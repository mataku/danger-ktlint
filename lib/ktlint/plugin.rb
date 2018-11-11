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

      target = git.added_files + git.modified_files
      return if target.empty?

      results = JSON.parse(`ktlint #{target.join(' ')} --reporter=json --relative`)
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
          markdown(file: result['file'], line: error['line'], message: error['message'])
        }
      }
    end

    private

    def ktlint_exists?
      system 'which ktlint > /dev/null 2>&1' 
    end
  end
end
