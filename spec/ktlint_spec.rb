# frozen_string_literal: true

require File.expand_path("spec_helper", __dir__)

module Danger
  describe Danger::DangerKtlint do
    let(:dangerfile) { testing_dangerfile }
    let(:plugin) { dangerfile.ktlint }

    it "should be a plugin" do
      expect(Danger::DangerKtlint.new(nil)).to be_a Danger::Plugin
    end

    describe "#lint" do
      before do
        allow_any_instance_of(Danger::DangerfileGitPlugin).to receive(:added_files).and_return(["spec/fixtures/KotlinFile.kt"])
        allow_any_instance_of(Danger::DangerfileGitPlugin).to receive(:modified_files).and_return([])
      end

      context "`ktlint` is not installed" do
        it "handles ktlint not being installed" do
          allow_any_instance_of(Kotlinlint).to receive(:installed?).and_return(false)
          expect { plugin.lint }.to raise_error("Couldn't find ktlint command. Install first.")
        end
      end

      context "Ktlint issues were found" do
        before do
          allow_any_instance_of(Kotlinlint).to receive(:installed?).and_return(true)
          allow(plugin.git).to receive(:added_files).and_return([])
          allow(plugin.git).to receive(:modified_files).and_return([])

          @ktlint_response = '[{ "file": "spec/fixtures/KotlinFile.kt", "errors": [{ "line": 1, "column": 1, "message": "File must end with a newline", "rule": "final-newline" }] }]'
        end

        it "Sends markdown comment" do
          expect_any_instance_of(Kotlinlint).to receive(:lint)
            .and_return(@ktlint_response)

          plugin.lint("spec/fixtures/*.kt")

          output = dangerfile.status_report[:markdowns].first.to_s
          expect(output).to include("ktlint found issues")
          expect(output).to include("KotlinFile.kt | 1 | File must end with a newline (final-newline)")
        end
      end

      context "Ktlint issues were found with inline_mode: true" do
        before do
          allow_any_instance_of(Kotlinlint).to receive(:installed?).and_return(true)
          allow(plugin.git).to receive(:added_files).and_return([])
          allow(plugin.git).to receive(:modified_files).and_return([])
          @ktlint_response = '[{ "file": "spec/fixtures/KotlinFile.kt", "errors": [{ "line": 1, "column": 1, "message": "File must end with a newline", "rule": "final-newline" }] }]'
        end

        it "Sends inline comment" do
          expect_any_instance_of(Kotlinlint).to receive(:lint)
            .and_return(@ktlint_response)

          plugin.lint("spec/fixtures/*.kt", inline_mode: true)
          expect(dangerfile.status_report[:errors].size).to eq(1)
        end
      end

      context "Filter issues in git diff" do
        it "Get git modified file line numbers" do
          git_diff = File.read("spec/fixtures/KotlinFile.diff")
          allow(plugin.git).to receive(:diff_for_file).and_return(git_diff)
          allow(plugin.git.diff_for_file).to receive(:patch).and_return(git_diff)
          modified_lines = plugin.git_modified_lines("spec/fixtures/KotlinFile.ktt")
          expect(modified_lines).to_not be_empty
          expect(modified_lines.length).to eql(23)
        end

        it "Get git modified files info" do
          allow(plugin.git).to receive(:added_files).and_return([])
          allow(plugin.git).to receive(:modified_files).and_return(["spec/fixtures/KotlinFile.kt", "spec/fixtures/DeletedFile.kt"])
          allow(plugin.git).to receive(:deleted_files).and_return(["spec/fixtures/DeletedFile.kt"])
          git_diff = File.read("spec/fixtures/KotlinFile.diff")
          allow(plugin.git).to receive(:diff_for_file).and_return(git_diff)
          allow(plugin.git.diff_for_file).to receive(:patch).and_return(git_diff)
          modified_files_info = plugin.git_modified_files_info
          expect(modified_files_info).to_not be_empty
          expect(modified_files_info.length).to eql(1)
        end

        it "filters lint issues to return issues in modified files based on git diff patch info" do
          allow_any_instance_of(Kotlinlint).to receive(:installed?).and_return(true)
          allow(plugin.git).to receive(:added_files).and_return([])
          allow(plugin.git).to receive(:modified_files).and_return(["spec/fixtures/KotlinFile.kt", "spec/fixtures/DeletedFile.kt"])
          allow(plugin.git).to receive(:deleted_files).and_return(["spec/fixtures/DeletedFile.kt"])

          git_diff = File.read("spec/fixtures/KotlinFile.diff")
          allow(plugin.git).to receive(:diff_for_file).and_return(git_diff)
          allow(plugin.git.diff_for_file).to receive(:patch).and_return(git_diff)

          ktlint_response = '[{ "file": "spec/fixtures/KotlinFile.kt", "errors":
          [{ "line": 16, "column": 1, "message": "File must end with a newline", "rule": "final-newline" },
          { "line": 46, "column": 1, "message": "Unexpected blank line(s) before", "rule": "no-blank-line-before-rbrace" }]
          }]'
          allow_any_instance_of(Kotlinlint).to receive(:lint)
            .and_return(ktlint_response)

          plugin.filter_issues_in_diff = true
          plugin.lint("spec/fixtures/*.kt", inline_mode: false, fail_on_error: false)

          output = dangerfile.status_report[:markdowns].first.to_s
          expect(output).to include("ktlint found issues")
          expect(output).to include("KotlinFile.kt | 16 | File must end with a newline (final-newline)")
          expect(output).to_not include("KotlinFile.kt | 46 | Unexpected blank line(s) before (no-blank-line-before-rbrace)")
        end
      end
    end
  end
end
