# frozen_string_literal: true

require 'json'

module Danger
  class DangerKtlint < Plugin
    class UnexpectedLimitTypeError < StandardError; end

    class UnsupportedServiceError < StandardError
      def initialize(message = 'Unsupported service! Currently supported services are GitHub, GitLab and BitBucket server.')
        super(message)
      end
    end

    AVAILABLE_SERVICES = [:github, :gitlab, :bitbucket_server]

    # TODO: Lint all files if `filtering: false`
    attr_accessor :filtering

    attr_accessor :skip_lint, :report_file

    def limit
      @limit ||= nil
    end

    def limit=(limit)
      if limit != nil && limit.integer?
        @limit = limit
      else
        raise UnexpectedLimitTypeError
      end
    end

    # Run ktlint task using command line interface
    # Will fail if `ktlint` is not installed
    # Skip lint task if files changed are empty
    # @return [void]
    # def lint(inline_mode: false)
    def lint(inline_mode: false)
      unless supported_service?
        raise UnsupportedServiceError.new
      end

      targets = target_files(git.added_files + git.modified_files)

      results = ktlint_results(targets)
      if results.nil? || results.empty?
        return
      end

      if inline_mode
        send_inline_comments(results, targets)
      else
        send_markdown_comment(results, targets)
      end
    end

    # Comment to a PR by ktlint result json
    #
    # // Sample ktlint result
    # [
    #   {
    #     "file": "app/src/main/java/com/mataku/Model.kt",
    # 		"errors": [
    # 			{
    # 				"line": 46,
    # 				"column": 1,
    # 				"message": "Unexpected blank line(s) before \"}\"",
    # 				"rule": "no-blank-line-before-rbrace"
    # 			}
    # 		]
    # 	}
    # ]
    def send_markdown_comment(results, targets)
      catch(:loop_break) do
        count = 0
        results.each do |result|
          result['errors'].each do |error|
            file_path = relative_file_path(result['file'])
            next unless targets.include?(file_path)

            message = "#{file_html_link(file_path, error['line'])}: #{error['message']}"
            fail(message)
            unless limit.nil?
              count += 1
              if count >= limit
                throw(:loop_break)
              end
            end
          end
        end
      end
    end

    def send_inline_comments(results, targets)
      catch(:loop_break) do
        count = 0
        results.each do |result|
          result['errors'].each do |error|
            file_path = relative_file_path(result['file'])
            next unless targets.include?(file_path)
            message = error['message']
            line = error['line']
            fail(message, file: result['file'], line: line)
            unless limit.nil?
              count += 1
              if count >= limit
                throw(:loop_break)
              end
            end
          end
        end
      end
    end

    def target_files(changed_files)
      changed_files.select do |file|
        file.end_with?('.kt')
      end
    end

    # Make it a relative path so it can compare it to git.added_files
    def relative_file_path(file_path)
      file_path.gsub(/#{pwd}\//, '')
    end

    private

    def file_html_link(file_path, line_number)
      file = if danger.scm_provider == :github
               "#{file_path}#L#{line_number}"
             else
               file_path
             end
      scm_provider_klass.html_link(file)
    end

    # `eval` may be dangerous, but it does not accept any input because it accepts only defined as danger.scm_provider
    def scm_provider_klass
      @scm_provider_klass ||= eval(danger.scm_provider.to_s)
    end

    def pwd
      @pwd ||= `pwd`.chomp
    end

    def ktlint_exists?
      system 'which ktlint > /dev/null 2>&1' 
    end

    def ktlint_results(targets)
      if skip_lint
        # TODO: Allow XML
        if report_file.nil? || report_file.empty?
          fail("If skip_lint is specified, You must specify ktlint report json file with `ktlint.report_file=...` in your Dangerfile.")
          return
        end

        unless File.exists?(report_file)
          fail("Couldn't find ktlint result json file.\nYou must specify it with `ktlint.report_file=...` in your Dangerfile.")
          return
        end

        File.open(report_file) do |f|
          JSON.load(f)
        end
      else
        unless ktlint_exists?
          fail("Couldn't find ktlint command. Install first.")
          return
        end

        return if targets.empty?

        JSON.parse(`ktlint #{targets.join(' ')} --reporter=json --relative`)
      end
    end

    def supported_service?
      AVAILABLE_SERVICES.include?(danger.scm_provider.to_sym)
    end
  end
end
