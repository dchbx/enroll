# frozen_string_literal: true

require_relative 'view_translations_linter_helper'

# This wll provide a report showing the status of translations in each individual directory
# To give an idea of what needs to be internationalized
class ViewTranslationsLinterReport
  VIEW_DIRECTORIES_AND_FILES = {
    main_app: [
      Dir[Rails.root.join('app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('app/views/**/**/*.haml')].uniq
    ],
    benefit_markets: [
      Dir[Rails.root.join('components/benefit_markets/app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('components/benefit_markets/app/views/**/**/*.haml')].uniq
    ],
    benefit_sponsors: [
      Dir[Rails.root.join('components/benefit_sponsors/app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('components/benefit_sponsors/app/views/**/**/*.haml')].uniq
    ],
    financial_assistance: [
      Dir[Rails.root.join('components/financial_assistance/app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('components/financial_assistance/app/views/**/**/*.haml')].uniq
    ],
    notifier: [
      Dir[Rails.root.join('components/notifier/app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('components/notifier/app/views/**/**/*.haml')].uniq
    ],
    sponsored_benefits: [
      Dir[Rails.root.join('components/sponsored_benefits/app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('components/sponsored_benefits/app/views/**/**/*.haml')].uniq
    ],
    transport_gateway: [
      Dir[Rails.root.join('components/transport_gateway/app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('components/transport_gateway/app/views/**/**/*.haml')].uniq
    ],
    transport_profiles: [
      Dir[Rails.root.join('components/transport_profiles/app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('components/transport_profiles/app/views/**/**/*.haml')].uniq
    ],
    ui_helpers: [
      Dir[Rails.root.join('components/ui_helpers/app/views/**/**/*.html.erb')].uniq,
      Dir[Rails.root.join('components/ui_helpers/app/views/**/**/*.haml')].uniq
    ]
  }.freeze

  def self.run
    VIEW_DIRECTORIES_AND_FILES.each do |directory_name, full_view_file_location_filenames|
      self.evaluate_views(directory_name, full_view_file_location_filenames)
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def self.evaluate_views(directory_name, filenames)
    views_missing_translations_both = []
    views_missing_translations_outside_erb = []
    views_missing_translations_inside_erb = []
    views_with_all_translations = []
    # ERB Views
    filenames[0].each do |full_file_location|
      if translations_in_erb_tags_present?(full_file_location) && translations_outside_erb_tags_present?(full_file_location)
        views_with_all_translations << full_file_location
      elsif !translations_in_erb_tags_present?(full_file_location) && translations_outside_erb_tags_present?(full_file_location)
        views_missing_translations_inside_erb << full_file_location
      elsif translations_in_erb_tags_present?(full_file_location) && !translations_outside_erb_tags_present?(full_file_location)
        views_missing_translations_outside_erb << full_file_location
      else
        views_missing_translations_both << full_file_location
      end
    end
    haml_views_missing_translations = []
    haml_views_with_translations_present = []
    if filenames[1].present?
      filenames[1].each do |full_file_location|
        if translations_in_haml_tags_present?(full_file_location)
          haml_views_with_translations_present << full_file_location
        else
          haml_views_missing_translations << full_file_location
        end
      end
    end
    if filenames[0].length == views_with_all_translations.length
      puts("All ERB translations present for #{directory_name}")
    else
      puts("For a total of #{filenames[0].length} ERB views in the #{directory_name} directory:")
      puts("There are a total of #{views_missing_translations_both.length} views with translations both inside and outside erb missing.")
      puts("There are a total of #{views_missing_translations_outside_erb.length} views with translations outside erb missing.")
      puts("There are a total of #{views_missing_translations_inside_erb.length} views with translations inside erb missing.")
      puts("There are a total of #{views_with_all_translations.length} views with all translations present.")
    end
    puts("")
    puts("For a total of #{filenames[1].length} HAML views in #{directory_name} directory:") if filenames[1].present?
    if filenames[1].length == haml_views_with_translations_present.length
      puts("All haml translations present for #{directory_name}.")
    else
      puts("There are a total of #{haml_views_missing_translations.length} haml views with missing translations.")
    end
    puts("")
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
end

