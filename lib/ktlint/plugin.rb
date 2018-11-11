module Danger
  class DangerKtlint < Plugin
    attr_accessor :filtering

    def lint(inline_mode: false)
      unless ktlint_exists?
        fail("Couldn't find ktlint command. Install first.")
        return
      end
    end

    private

    def ktlint_exists?
      system 'which ktlint > /dev/null 2>&1' 
    end
  end
end
