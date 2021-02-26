# frozen_string_literal: true

# This will check a list of view files for any untranslated strings
# For Ex: RAILS_ENV=production bundle exec rake view_translations_linter_report:run

require "#{Rails.root}/lib/custom_linters/translations/view_translations_linter_report.rb"

namespace :view_translations_linter_report do
  desc("Runs a report of the total translation status for entire application.")
  task :run do
    puts("Running view translations linter report.") unless Rails.env.test?
    ViewTranslationsLinterReport.run
    puts("View translations linter report complete.") unless Rails.env.test?
  end
end
