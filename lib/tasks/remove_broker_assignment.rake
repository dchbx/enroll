require 'csv'
namespace :migrations do
  desc "Remove broker assignment of given list in CSV file"
  task :remove_broker_assignment => :environment do
    field_names  = %w(
    Primary_Person_full_name
    Broker_agency_legal_name
    Status
    )
    file_name = "#{Rails.root}/ivl_broker_assignments_to_be_removed_20160105_output.csv"
    CSV.foreach("#{Rails.root}/ivl_broker_assignments_to_be_removed_20160105.csv", headers: true) do |row|
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        if !Person.by_ssn(row['SSN']).present?
          puts "Person not found #{row['SSN']}" unless Rails.env.test?
        else
          person = Person.by_ssn(row['SSN']).first
          family = person.primary_family.present? ? person.primary_family : ( person.families.count == 1 ? person.families.first : nil )
          if family.present? && family.current_broker_agency.present?
            broker_legal_name = family.current_broker_agency.legal_name
            csv << [person.full_name,
                    broker_legal_name,
                    "Delinked broker assignment of #{person.full_name}"
                   ]
            family.current_broker_agency.update_attributes!(is_active: false)
            puts "Removed broker for the primary family with primary person - #{person.full_name}  with SSN: #{row['SSN']}" unless Rails.env.test?
          else
            puts "'#{person.full_name}' doesn't have any broker agency linked" unless Rails.env.test?
          end
        end
      end
    end
  end
end
