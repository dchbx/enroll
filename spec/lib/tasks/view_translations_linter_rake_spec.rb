# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Lint list of translation files for missing translations", :type => :task, dbclean: :after_each do
  let(:task_command) { "bundle exec rake view_translations_linter:lint_files view_files_list='spec/support/fake_view.html.erb'"}

  context "running rake task" do
    it "should invoke without errors" do
      expect { system task_command }.to_not raise_error
    end
  end
end
