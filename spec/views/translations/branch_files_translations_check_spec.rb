# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/spec/support/view_translations_linter.rb"

# This will check the git diff for all .html.erb files and match all non HTML/ERB tag substrings
# against all the translations in the database to assure translations are added to the file.

RSpec.describe "Branch Files Translations Spec" do
  # Returns any changed ERB files froom current branch
  let(:filename_list) { `git diff --name-only origin/master HEAD | grep .html.erb`.strip.split("\n") }
  # Will read all ERB filesfrom branch  and and return an array of all of them as strings
  let(:read_view_files) { filename_list.map { |view_filename| File.read("#{Rails.root}/#{view_filename}") } }
  # YML file containing approved strings.
  # Note: Do NOT add to approved strings without lead dev approval
  let(:approved_strings_hash) { YAML.load_file("#{Rails.root}/spec/support/fixtures/approved_translation_strings.yml").with_indifferent_access }
  let(:approved_translation_strings_in_erb_tags) do
    all_approved_strings = []
    keys = approved_strings_hash[:approved_translation_strings_in_erb_tags].keys
    keys.each do |key|
      all_approved_strings << approved_strings_hash[:approved_translation_strings_in_erb_tags][key]
    end
    all_approved_strings.flatten
  end

  let(:approved_translation_strings_outside_erb_tags) do
    all_approved_strings = []
    keys = approved_strings_hash[:approved_translation_strings_outside_erb_tags].keys
    keys.each do |key|
      all_approved_strings << approved_strings_hash[:approved_translation_strings_outside_erb_tags][key]
    end
    all_approved_strings.flatten
  end

  let(:translations_linter_in_erb) { ViewTranslationsLinter.new(read_view_files, approved_translation_strings_in_erb_tags, 'in_erb') }
  let(:translations_linter_outside_erb) { ViewTranslationsLinter.new(read_view_files, approved_translation_strings_outside_erb_tags, 'outside_erb') }

  xit "should not contain any ERB tags containing untranslated strings" do
    expect(translations_linter_in_erb.all_translations_present?).to eq(true)
  end

  xit "should not contain any untranslated substrings outside of HTML tags" do
    expect(translations_linter_outside_erb.all_translations_present?).to eq(true)
  end
end
