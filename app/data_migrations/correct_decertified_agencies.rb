require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectDecertifiedAgency < MongoidMigrationTask
  def broker_feins
    #fein:"521698168" is General Agency Profile of 'Insurance Marketing Center'
    fein = ENV['fein'] ? ENV['fein'].to_s : "521698168"
    general_agency_profile_id = Organization.where(fein:fein).first.general_agency_profile.id if Organization.where(fein:fein).first
    Organization.by_general_agency_profile(general_agency_profile_id).map(&:employer_profile).map(&:broker_agency_profile).map(&:fein) if general_agency_profile_id
  end



  def migrate
    if broker_feins.any?
      broker_feins.each_with_index do |fein, i|
        broker_agency_profile = Organization.where(fein:fein).first.broker_agency_profile
        general_agencies = broker_agency_profile.employer_clients.map(&:active_general_agency_account)
        general_agencies.each do |ga|
          if ga && ga.legal_name == "Insurance Marketing Center"
            ga.delete
            puts "broker# #{i+1} Broker: #{broker_agency_profile.legal_name}, GA LegalName: #{ga.legal_name} deleted from employer account." unless Rails.env.test?
          end
        end
      end
    end
  end
end
