# frozen_string_literal: true
# Run it with this: bundle exec rake app:seed:load_faa_translations

require 'rake'

namespace :seed do
  desc "load translations from faa engine translations file"
  task :load_faa_translations => :environment do
    # TODO: Load from file
    # en =  YAML::load(File.read(File.open("db/seedfiles/translations/en/faa_translations.rb",'r')))
    ASSISTANCE_TRANSLATIONS = {
      "en.faa.curam_lookup" => "It looks like you've already completed an application for Medicaid and cost savings on DC Health Link. Please call DC Health Link at (855) 532-5465 to make updates to that application. If you keep going, we'll check to see if you qualify to enroll in a private health insurance plan on DC Health Link, but won't be able to tell you if you qualify for Medicaid or cost savings.",
      "en.faa.acdes_lookup" => "It looks like you're already covered by Medicaid. Please call DC Health Link at (855) 532-5465 to make updates to your case. If you keep going, we'll check to see if you qualify to enroll in a private health insurance plan on DC Health Link, but won't be able to tell you if you qualify for Medicaid or cost savings.",

      "en.faa.other_ques.disability_question" => "Does this person have a disability? *"
    }.freeze
    puts "Loading en FAA translation...."

    ASSISTANCE_TRANSLATIONS.each_key do |key|
      value = ASSISTANCE_TRANSLATIONS[key]
      Translation.create(key: key, value: "\"#{value}\"")
    end
    puts "Loaded #{Translation.all.count} translations."
  end
end
