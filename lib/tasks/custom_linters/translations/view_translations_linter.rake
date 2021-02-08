# frozen_string_literal: true

# This will check a list of view files for any untranslated strings
# For Ex: RAILS_ENV=production bundle exec rake view_translations_linter:lint_git_difference_changed_lines

require "#{Rails.root}/lib/custom_linters/translations/view_translations_linter.rb"
require "#{Rails.root}/lib/custom_linters/translations/view_translations_linter_helper.rb"
include ViewTranslationsLinterHelper

namespace :view_translations_linter do
  desc("Lints lines from view files changed since master")
  task :lint_git_difference_changed_lines do
    puts("Linting the following files: #{branch_changed_filenames_erb}") if branch_changed_filenames_erb.present?
    puts("")
    puts("")
    changed_files_with_linting_errors = []
    branch_changed_filenames_erb.each do |filename|
      changed_lines_key_values = {}
      changed_lines_string = changed_lines_from_file_string(filename)
      changed_lines_key_values[filename] = changed_lines_string
      translations_linter_in_erb = ViewTranslationsLinter.new(changed_lines_key_values, approved_translation_strings_in_erb_tags, 'in_erb')
      translations_linter_outside_erb = ViewTranslationsLinter.new(changed_lines_key_values, approved_translation_strings_outside_erb_tags, 'outside_erb')
      unless translations_linter_in_erb.all_translations_present?
        changed_files_with_linting_errors << filename
      end
      unless translations_linter_outside_erb.all_translations_present?
        changed_files_with_linting_errors << filename
      end
    end
    if changed_files_with_linting_errors.present?
      puts("Please modify your ERB and place them in translation helper tags with a coorelating translation or add them to the approved string list.")
      abort
    else
      puts("Translations linting complete. No errors present in ERB files.")
    end
    # Haml
    puts("Linting the following haml files: #{branch_changed_filenames_haml}") if branch_changed_filenames_haml.present?
    puts("")
    puts("")
    changed_haml_files_with_linting_errors = []
    branch_changed_filenames_haml.each do |filename|
      changed_lines_key_values = {}
      changed_lines_string = changed_lines_from_file_string(filename)
      changed_lines_key_values[filename] = changed_lines_string
      translations_linter_haml = ViewTranslationsLinter.new(changed_lines_key_values, approved_translation_strings_in_erb_tags, 'in_haml_ruby_tags')
      unless translations_linter_haml.all_translations_present?
        changed_haml_files_with_linting_errors << filename
      end
    end
    if changed_haml_files_with_linting_errors.present?
      puts("Please modify your HAML and place them in translation helper tags with a coorelating translation or add them to the approved string list.")
      abort
    else
      puts("Translations linting complete. No untranslated strings present in HAML files.")
    end
  end
end
