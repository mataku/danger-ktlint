# frozen_string_literal: true

require "json"
require "shellwords"
require_relative "../../ext/ktlint/kotlinlint"

module Danger
  # Danger ktlint plugin class to lint kotlin files
  # Supports linting all files or given files or all files in a directory
  # @example Running linter with default linters
  #
  #   # Runs a linter with all styles, on modified and added markdown files in this PR
  #   ktlint.lint
  # @see artsy/ktlint.github.io
  # @tags ktlint, danger, danger-ktlint, PR linting
  class DangerKtlint < Plugin
    # Whether all issues or ones in PR Diff to be reported
    #
    # @return [Bool]
    attr_accessor :filter_issues_in_diff

    # Provides additional logging diagnostic information.
    #
    # @return [Bool]
    attr_accessor :verbose

    # A path to a JAR file containing additional ruleset(s)
    #
    # @return [String]
    attr_accessor :ruleset_file

    # Turn on Android Kotlin Style Guide compatibility
    #
    # @return [Bool]
    attr_accessor :android_style

    # Whether all files should be linted in one pass
    #
    # @return [Bool]
    attr_accessor :lint_all_files

    # Maximum number of errors to show (default: show all)
    #
    # @return [Int]
    attr_accessor :limit

    # Allows you to specify a directory from where ktlint will be run.
    #
    # @return [String]
    attr_accessor :directory

    # The path to ktlint's execution
    #
    # @return [String]
    attr_accessor :binary_path

    # Run ktlint task using command line interface
    # Will fail if `ktlint` is not installed
    # @return [void]
    # def lint(inline_mode: false, files: nil, fail_on_error: false)
    def lint(files = nil, inline_mode: false, fail_on_error: false)
      # Fails if ktlint isn't installed
      raise "Couldn't find ktlint command. Install first." unless ktlint.installed?

      log "Using additional ruleset file: #{ruleset_file}" if ruleset_file

      dir_selected = directory ? File.expand_path(directory) : Dir.pwd
      log "ktlint will be run from #{dir_selected}"

      # Prepare ktlint options
      options = {
        # Make sure we don't fail when ruleset path has spaces
        ruleset: ruleset_file ? Shellwords.escape(ruleset_file) : nil,
        reporter: "json",
        pwd: dir_selected,
        android: android_style,
        limit: limit
      }
      log "linting with options: #{options}"

      if lint_all_files
        issues = run_ktlint(options)
      else
        # Extract Kotlin files (ignoring excluded ones)
        files = find_kotlin_files(dir_selected, files)
        log "ktlint will lint the following files: #{files.join(', ')}"

        # Lint each file and collect the results
        issues = run_ktlint_for_each(files, options)
      end

      log "Received from ktlint: #{issues}"

      if filter_issues_in_diff
        # Filter issues related to changes in PR Diff
        issues = filter_git_diff_issues(issues)
      end

      if issues.empty?
        log "ktlint - No issues found!!!"
        return
      end

      if inline_mode
        send_inline_comments(issues)
      else
        send_markdown_comment(issues)
        # Fail danger on errors
        fail "Failed due to ktLint errors" if fail_on_error
      end
    end

    # Find  files from the files glob
    # If files are not provided it will use git modifield and added files
    #
    # @return [Array] kotlin files
    def find_kotlin_files(dir_selected, files = nil, excluded_paths = [], included_paths = [])
      # Needs to be escaped before comparsion with escaped file paths
      dir_selected = Shellwords.escape(dir_selected)

      # Assign files to lint
      files = if files.nil?
                (git.modified_files - git.deleted_files) + git.added_files
              else
                Dir.glob(files)
              end
      # Filter files to lint
      files.
        # Ensure only Kotlin files are selected
        select { |file| file.end_with?(".kt") }.
        # Make sure we don't fail when paths have spaces
        map { |file| Shellwords.escape(File.expand_path(file)) }.
        # Remove dups
        uniq.
        # Ensure only files in the selected directory
        select { |file| file.start_with?(dir_selected) }.
        # Reject files excluded on configuration
        reject { |file| file_exists?(excluded_paths, file) }.
        # Accept files included on configuration
        select do |file|
        next true if included_paths.empty?

        file_exists?(included_paths, file)
      end
    end

    # Comment to a PR by ktlint result json
    #
    # // Sample ktlint result
    # [{ "file": "app/src/main/java/com/mataku/Model.kt", "errors": [{ "line": 46, "column": 1, "message": "Unexpected blank line(s) before \"}\"", "rule": "no-blank-line-before-rbrace" }] }]
    #
    # @return [void]
    #
    def send_markdown_comment(results)
      message = "### ktlint found issues\n\n".dup
      message << "File | Line | Reason |\n"
      message << "| --- | ----- | ----- |\n"
      results.each do |result|
        result["errors"].each do |error|
          filename = result["file"].split("/").last
          line = error["line"]
          reason = error["message"]
          rule = error["rule"]
          message << "#{filename} | #{line} | #{reason} (#{rule})\n"
        end
      end
      markdown message
    end

    # Added inline comments in PR
    #
    # @return [void]
    def send_inline_comments(results)
      results.each do |result|
        result["errors"].each do |error|
          file = result["file"]
          message = error["message"]
          line = error["line"]
          fail(message, file: file, line: line)
        end
      end
    end

    # Filters changed files to return kotlin files
    #
    # @return [String] Array of kotlin files
    #
    def target_files(changed_files)
      changed_files.select do |file|
        file.end_with?(".kt")
      end
    end

    # Filters issues reported against changes in the modified files
    #
    # @return [Array] ktlint issues
    def filter_git_diff_issues(issues)
      modified_files_info = git_modified_files_info
      return [] if modified_files_info.empty?

      filtered_issues = []
      issues.each do |issue|
        file = issue["file"].to_s
        next if modified_files_info[file].nil? || modified_files_info[file].empty?

        filtered_errors = issue["errors"].select { |error| modified_files_info[file].include?(error["line"].to_i) }
        filtered_issues << { "file" => file, "errors" => filtered_errors } unless filtered_errors.empty?
      end
      filtered_issues
    end

    # Finds modified files and added files, creates array of files with modified line numbers
    #
    # @return [Array] Git diff changes for each file
    def git_modified_files_info
      modified_files_info = {}
      updated_files = (git.modified_files - git.deleted_files) + git.added_files
      updated_files.each do |file|
        modified_lines = git_modified_lines(file)
        modified_files_info[file] = modified_lines
      end
      modified_files_info
    end

    # Gets git patch info and finds modified line numbers, excludes removed lines
    #
    # @return [Array] Modified line numbers i
    def git_modified_lines(file)
      git_range_info_line_regex = /^@@ .+\+(?<line_number>\d+),/
      git_modified_line_regex = /^\+(?!\+|\+)/
      file_info = git.diff_for_file(file)
      line_number = 0
      lines = []
      file_info.patch.split("\n").each do |line|
        starting_line_number = 0
        case line
        when git_range_info_line_regex
          starting_line_number = Regexp.last_match[:line_number].to_i
        when git_modified_line_regex
          lines << line_number
        end
        line_number += 1 if line_number.positive?
        line_number = starting_line_number if line_number.zero? && starting_line_number.positive?
      end
      lines
    end

    private

    # Run ktlint on all files and returns the issues
    #
    # @return [Array] ktlint issues
    def run_ktlint(options)
      result = ktlint.lint(options)
      if result == ''
        {}
      else
        JSON.parse(result).flatten
      end
    end

    # Run ktlint on each file and aggregate collect the issues
    #
    # @return [Array] ktlint issues
    #
    def run_ktlint_for_each(files, options)
      files
        .map { |file| options.merge(path: file) }
        .map { |full_options| ktlint.lint(full_options) }
        .reject { |s| s == "" }
        .map { |s| JSON.parse(s) }
        .flatten
    end

    def log(text)
      puts(text) if @verbose
    end

    # Make KtLint object for binary_path
    #
    # @return [Ktlint]
    def ktlint
      Kotlinlint.new(binary_path)
    end

    # Return whether the file exists within a specified collection of paths
    #
    # @return [Bool] file exists within specified collection of paths
    def file_exists?(paths, file)
      paths.any? do |path|
        Find.find(path)
          .map { |path_file| Shellwords.escape(path_file) }
          .include?(file)
      end
    end
  end
end
