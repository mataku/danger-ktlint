require 'json'

module Danger
  class DangerKtlint < Plugin
    attr_accessor :filtering

    # Run ktlint task using command line interface
    # Will fail if `ktlint` is not installed
    # Skip lint task if files changed are empty
    # @return [void]
    def lint(inline_mode: false)
      unless ktlint_exists?
        fail("Couldn't find ktlint command. Install first.")
        return
      end

      targets = target_files(git.added_files + git.modified_files)
      return if targets.empty?

      results = JSON.parse(`ktlint #{targets.join(' ')} --reporter=json --relative`)
      return if results.empty?

      if inline_mode
        # TODO: Send inline comment
      else
        send_markdown_comment(results)
      end
    end

    def send_markdown_comment(results)
      results.each {|result|
        result['errors'].each {|error|
          file = "#{result['file']}#L#{error['line']}"
          message = "#{github.html_link(file)} has linter issue: #{error['message']}"
          fail(message)
        }
      }
    end

    def target_files(changed_files)
      changed_files.select do |file|
        file.end_with?('.kt')
      end
    end

    private

    def ktlint_exists?
      system 'which ktlint > /dev/null 2>&1' 
    end
  end
end
