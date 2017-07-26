require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveInvalidBrokerAgencyAccountsForEmployer< MongoidMigrationTask

  def migrate
    begin
      organization = Organization.where(fein:ENV['fein']).first
      if organization.present?
        organization.employer_profile.broker_agency_accounts.unscoped.each do |broker_agency_account|
          if broker_agency_account.writing_agent.blank? || broker_agency_account.broker_agency_profile.blank?
            broker_agency_account.delete
            puts "deleted invalid broker_agency_account for organization: #{organization.legal_name}" unless Rails.env.test?
          else
            puts "unable to delete broker_agency_account, broker_agency_account has writing agenct & broker_agency_profile" unless Rails.env.test?
          end
        end
      else
        puts "No organization found by the given fein" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
