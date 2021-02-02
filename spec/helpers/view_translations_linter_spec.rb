# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/spec/support/view_translations_linter.rb"

RSpec.describe ViewTranslationsLinter do
  context "#all_translations_present" do
    context "no filename list present" do
      let(:linter_no_filename_list) { ViewTranslationsLinter.new(nil, ["approved String"], 'in_erb')}
      it "should return true" do
        expect(linter_no_filename_list.all_translations_present?).to eq(true)
      end
    end

    context "approved_translation_strings" do
      context "non approved string passed" do
        let(:linter_with_non_approved_string) { ViewTranslationsLinter.new({fake_view_filename: "<%= 'Non-approved String' %>"}, [], 'in_erb')}
        it "should give puts output showing that the special - char was passed" do
          $stdout = StringIO.new
          linter_with_non_approved_string.all_translations_present?
          $stdout.rewind
          expect($stdout.string).to eq("The following are potentially untranslated substrings missing IN_ERB from fake_view_filename:\n'non-approved string'\n")
        end
      end

      context "approved string passed" do
        let(:linter_with_approved_string) { ViewTranslationsLinter.new({fake_view_filename: "render approved string"}, ["approved String", "render"], 'in_erb')}
        it "should return true" do
          expect(linter_with_approved_string.all_translations_present?).to eq(true)
        end
      end

      context "approved method calls from approve list YML" do
        let(:linter_with_unapproved_method_string) do
          ViewTranslationsLinter.new(
            {fake_view_filename: "<%= family.primary_person.full_name %> <%= benefit_application.created_at %> <%= person.id %> <%= family.hbx_enrollments.map(&:hbx_id) %>"},
            approved_method_call_strings,
            'in_erb'
          )
        end
        let(:approved_method_call_strings) do
          approved_translations_hash = YAML.load_file("#{Rails.root}/spec/support/fixtures/approved_translation_strings.yml").with_indifferent_access
          approved_translations_hash[:approved_translation_strings_in_erb_tags][:record_method_calls]
        end

        it "should return true" do
          expect(linter_with_unapproved_method_string.all_translations_present?).to eq(true)
        end
      end
    end
  end
end
