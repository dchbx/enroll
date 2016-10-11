require 'csv'

namespace :qle do
  desc "Populate date_options_available"
  task populate_date_options_available: :environment do
    QualifyingLifeEventKind.where(title: /Health plan contract violation/i).each do |qle|
      qle.update_attributes!(date_options_available: true)
    end
  end
end