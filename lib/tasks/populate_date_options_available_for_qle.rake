require 'csv'

namespace :qle do
  desc "Populate date_options_available"
  task populate_date_options_available: :environment do
    # QLE with Date options 
    qles_titles = [  "Enrollment error caused by DC Health Link",
              "Enrollment error caused by my health insurance company",
              "Enrollment error caused by someone providing me with enrollment assistance",
              "Health plan contract violation",
              "Found ineligible for Medicaid after open enrollment ended",
              "Found ineligible for employer-sponsored insurance after open enrollment ended",
              "A natural disaster prevented enrollment",
              "A medical emergency prevented enrollment",
              "System outage prevented enrollment",
              "Domestic abuse",
              "Lost eligibility for a hardship exemption",
              "Court order to provide coverage for someone",
              "Employer did not pay premiums on time"]
    qles_titles.each do |qle_title|
      QualifyingLifeEventKind.where(title: qle_title).each do |qle|
        qle.update_attributes!(date_options_available: true)
      end
  end
  end
end