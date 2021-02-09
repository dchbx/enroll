# frozen_string_literal: true

# This module defines methods related to ViewTranslationsLinter to be reused in
# Rake files, specs, etc.

require_relative 'view_translations_linter'

module ViewTranslationsLinterHelper
  # Approved list data
  def approved_translations_hash
    YAML.load_file("#{Rails.root}/config/translations_linter/approved_translation_strings.yml").with_indifferent_access
  end

  def included_substring_string_in_erb
    (
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:conditional_logic_methods] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:form_instance_variables] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:html_elements_and_helper_methods] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:dynamic_css_classes] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:non_word_numerical_strings] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:proper_name_related_strings] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:websites] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:record_identifiers] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:settings] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:string_method_calls] +
      approved_translations_hash[:approved_translation_strings_in_erb_tags][:record_method_calls]
    ).flatten
  end

  # In ERB
  def regex_matched_substrings_in_erb
    []
  end

  def approved_exact_match_strings_in_erb
    (approved_translations_hash[:approved_translation_strings_in_erb_tags][:array_counter_variables] +
     approved_translations_hash[:approved_translation_strings_in_erb_tags][:html_safe_one_liners] +
    approved_translations_hash[:approved_translation_strings_in_erb_tags][:instance_variables] +
    approved_translations_hash[:approved_translation_strings_in_erb_tags][:unique_variable_names] +
    approved_translations_hash[:approved_translation_strings_in_erb_tags][:health_product_info_methods] +
    # Returns exact array of all path strings, I.E. users_path
    # This violates the conventions so far from not being included in the YML, so this might need some
    # refactoring if its found to be confusing
    Rails.application.routes.named_routes.helper_names +
    approved_translations_hash[:approved_translation_strings_in_erb_tags][:exact_match_strings]).flatten
  end

  # Outside ERB
  # TODO: Outside of the testing environment, there aren't many hard coded strings outside of ERB tags
  # which I've come across to allow here. This will be updated in the future.
  def approved_exact_match_strings_outside_erb
    approved_translations_hash[:approved_translation_strings_outside_erb_tags][:exact_match_string_list]
  end

  def regex_matched_substrings_outside_erb
    []
  end

  def included_substring_string_outside_erb
    []
  end

  def translations_in_erb_tags_present?(file_location)
    stringified_view = File.read(file_location.to_s)
    ViewTranslationsLinter.new({file_location.to_s => stringified_view}, approved_translation_strings_in_erb_tags, 'in_erb').all_translations_present?
  end

  def translations_outside_erb_tags_present?(file_location)
    stringified_view = File.read(file_location.to_s)
    ViewTranslationsLinter.new({file_location.to_s => stringified_view}, approved_translation_strings_outside_erb_tags, 'outside_erb').all_translations_present?
  end

  def translations_in_haml_tags_present?(file_location)
    stringified_view = File.read(file_location.to_s)
    ViewTranslationsLinter.new({file_location.to_s => stringified_view}, approved_translation_strings_in_erb_tags, 'in_haml_ruby_tags').all_translations_present?
  end

  def branch_changed_filenames_erb
    # Returns array of changed files ending in .html.erb and not .html.erb specs
    # TOOD: Returns nil for some reason when this is added grep -v 'spec/'  needs to be included
    `git diff --name-only origin/master HEAD | grep .html.erb`.strip.split("\n").reject { |filename| filename.match('_spec.rb').present? }
  end

  def branch_changed_filenames_haml
    `git diff --name-only origin/master HEAD | grep .haml`.strip.split("\n").reject { |filename| filename.match('_spec.rb').present? }
  end

  def changed_lines_from_file_string(filename)
    `git diff HEAD^ HEAD  --unified=0 #{filename} | tail +6 | sed -e 's/^\+//'`
  end

  def approved_translation_strings_in_erb_tags
    {
      :exact_match_strings => approved_exact_match_strings_in_erb,
      :regex_match_strings => regex_matched_substrings_in_erb,
      :substring_included_strings => included_substring_string_in_erb
    }
  end

  def approved_translation_strings_outside_erb_tags
    {
      :exact_match_strings => approved_exact_match_strings_outside_erb,
      :regex_match_strings => regex_matched_substrings_outside_erb,
      :substring_included_strings => included_substring_string_outside_erb
    }
  end
end