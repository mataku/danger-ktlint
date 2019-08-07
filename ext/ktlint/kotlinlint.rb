# frozen_string_literal: true

# A wrapper to use ktlint via a Ruby API.
class Kotlinlint
  def initialize(ktlint_path = nil)
    @ktlint_path = ktlint_path
  end

  # Runs ktlint
  def lint(options = {})
    # change pwd before run ktlint
    Dir.chdir options.delete(:pwd) if options.key? :pwd

    # run ktlint with provided options
    `#{ktlint_path} #{ktlint_arguments(options)}`
  end

  # Return true if ktlint is installed or false otherwise
  def installed?
    File.exist?(ktlint_path)
  end

  # Return ktlint execution path
  def ktlint_path
    puts "Default ktlint path #{default_ktlint_path}"
    @ktlint_path || default_ktlint_path
  end

  private

  # Parse options into shell arguments how ktlint expect it to be
  # more information: https://github.com/Carthage/Commandant
  # @param options (Hash) hash containing ktlint options
  def ktlint_arguments(options)
    (options.
      # filter not null
      reject { |_key, value| value.nil? }.
      # map booleans arguments equal true
      map { |key, value| value.is_a?(TrueClass) ? [key, ""] : [key, value] }.
      # map booleans arguments equal false
      map { |key, value| value.is_a?(FalseClass) ? ["no-#{key}", ""] : [key, value] }.
      # replace underscore by hyphen
      map { |key, value| [key.to_s.tr('_', '-'), value] }.
      # prepend '--' into the argument
      map { |key, value| ["--#{key}", value] }.
      # reduce everything into a single string
      reduce('') { |args, option| option[1] == "" ? "#{args} #{option[0]}" : "#{args} #{option[0]}=#{option[1]}" }).
      # strip leading spaces
      strip
  end

  # Path where ktlint should be found
  def default_ktlint_path
    File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'ktlint'))
  end

end
