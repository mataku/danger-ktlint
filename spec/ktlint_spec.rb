require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerKtlint do
    let(:dangerfile) { testing_dangerfile }
    let(:plugin) { dangerfile.ktlint }

    it "should be a plugin" do
      expect(Danger::DangerKtlint.new(nil)).to be_a Danger::Plugin
    end

    describe '#lint' do
      before do
        allow_any_instance_of(Danger::DangerfileGitPlugin).to receive(:added_files).and_return(['app/src/main/java/com/mataku/Model.kt'])
        allow_any_instance_of(Danger::DangerfileGitPlugin).to receive(:modified_files).and_return([])
      end

      context '`ktlint` is not installed' do
        before do
          allow_any_instance_of(Kernel).to receive(:system).with('which ktlint > /dev/null 2>&1').and_return(false)
        end

        it 'Fails with message about not found `ktlint`' do
          plugin.lint(inline_mode: false)
          expect(dangerfile.status_report[:errors]).to eq(["Couldn't find ktlint command. Install first."])
        end
      end

      context 'Ktlint issues were found' do
        before do
          allow_any_instance_of(Kernel).to receive(:system).with('which ktlint > /dev/null 2>&1').and_return(true)
          allow_any_instance_of(Kernel).to receive(:`).with('ktlint app/src/main/java/com/mataku/Model.kt --reporter=json --relative').and_return(dummy_ktlint_result)
          allow_any_instance_of(Danger::DangerfileGitHubPlugin).to receive(:html_link).with('app/src/main/java/com/mataku/Model.kt#L46').and_return("<a href='https://github.com/mataku/android/blob/561827e46167077b5e53515b4b7349b8ae04610b/Model.kt'>Model.kt</a>")
        end

        it 'Sends markdown comment' do
          plugin.lint(inline_mode: false)
          expect(dangerfile.status_report[:errors].size).to eq(1)
        end
      end
    end
  end
end
