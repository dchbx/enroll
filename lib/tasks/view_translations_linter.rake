# This will check a list of view files for any untranslated strings
# For Ex: RAILS_ENV=production bundle exec rake view_translations_linter:lint_files view_files_list='spec/support/fake_view.html.erb'

require Rails.root.to_s + "/spec/support/view_translations_linter.rb"

namespace :view_translations_linter do
  desc "Lint list of translation files for missing translations"
  task :lint_files, :environment do
    # Approved list data
    approved_translations_hash = YAML.load_file(Rails.root.to_s + "/spec/support/fixtures/approved_translation_strings.yml").with_indifferent_access

    approved_translation_strings_in_erb_tags = []
    keys = approved_translations_hash[:approved_translation_strings_in_erb_tags].keys
    keys.each do |key|
      approved_translation_strings_in_erb_tags << approved_translations_hash[:approved_translation_strings_in_erb_tags][key]
    end
    approved_translation_strings_in_erb_tags = approved_translation_strings_in_erb_tags.flatten

    approved_translation_strings_outside_erb_tags = []
    keys = approved_translations_hash[:approved_translation_strings_outside_erb_tags].keys
    keys.each do |key|
      approved_translation_strings_outside_erb_tags << approved_translations_hash[:approved_translation_strings_outside_erb_tags][key]
    end
    approved_translation_strings_outside_erb_tags = approved_translation_strings_outside_erb_tags.flatten

    view_files_list_names = ENV['view_files_list'].split(" ")
    puts("Linting " + view_files_list_names.inspect) unless Rails.env.test?
    read_view_files_list = view_files_list_names.map { |view_filename| File.read("#{Rails.root}/#{view_filename}") }

    translations_linter_in_erb = ViewTranslationsLinter.new(read_view_files_list, approved_translation_strings_in_erb_tags, 'in_erb')
    translations_linter_outside_erb = ViewTranslationsLinter.new(read_view_files_list, approved_translation_strings_outside_erb_tags, 'outside_erb')

    # Run Task
    if translations_linter_in_erb.all_translations_present?
      puts("All translations present between ERB tags") unless Rails.env.test?
    else
      abort("Missing translations between ERB tags") unless Rails.env.test?
    end

    if translations_linter_outside_erb.all_translations_present?
      puts("All translations present outside ERB tags") unless Rails.env.test?
    else
      abort("Missing translations outside ERB tags") unless Rails.env.test?
    end
  end
end
