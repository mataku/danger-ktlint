require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerKtlint do
    it "should be a plugin" do
      expect(Danger::DangerKtlint.new(nil)).to be_a Danger::Plugin
    end
  end
end
