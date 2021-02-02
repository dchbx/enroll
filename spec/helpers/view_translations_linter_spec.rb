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
          expect($stdout.gets.strip).to include("The following are potentially untranslated substrings missing IN_ERB from fake_view_filename: 'non-approved string'")
        end
      end

      context "approved string passed" do
        let(:linter_with_approved_string) { ViewTranslationsLinter.new({fake_view_filename: "render approved string"}, ["approved String", "render"], 'in_erb')}
        it "should return true" do
          expect(linter_with_approved_string.all_translations_present?).to eq(true)
        end
      end
    end
  end
end
