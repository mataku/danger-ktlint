# frozen_string_literal: true

require File.expand_path("spec_helper", __dir__)
require_relative "../ext/ktlint/kotlinlint"

describe Kotlinlint do
  let(:ktlint) { Kotlinlint.new }
  it "installed? works based on bin/ktlint file" do
    expect(File).to receive(:exist?).with(%r{/bin\/ktlint}).and_return(true)
    expect(ktlint.installed?).to be_truthy

    expect(File).to receive(:exist?).with(%r{bin\/ktlint}).and_return(false)
    expect(ktlint.installed?).to be_falsy
  end

  context "with binary_path" do
    let(:binary_path) { "/path/to/ktlint" }
    let(:ktlint) { Kotlinlint.new(binary_path) }
    it "installed? works based on specific path" do
      expect(File).to receive(:exist?).with(binary_path).and_return(true)
      expect(ktlint.installed?).to be_truthy

      expect(File).to receive(:exist?).with(binary_path).and_return(false)
      expect(ktlint.installed?).to be_falsy
    end
  end

  it "lint by default with options being optional" do
    expect(ktlint).to receive(:`).with(including("ktlint"))
    ktlint.lint
  end

  it "lint accepting symbolized options" do
    cmd = "ktlint --ruleset=spec/fixtures/rules.jar --reporter=json --android --limit=20"
    expect(ktlint).to receive(:`).with(including(cmd))

    ktlint.lint(ruleset: "spec/fixtures/rules.jar",
                  reporter: "json",
                  android: true,
                  limit: 20)
  end
end
