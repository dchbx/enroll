require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDuplicateBrokerAgencyAccounts < MongoidMigrationTask
  def migrate
    families = Family.where("broker_agency_accounts" => {"$exists" => true})
  
    families.each do |fam|
      broker_accounts = fam.broker_agency_accounts
      if broker_accounts.size > 1
        record_one = broker_accounts[0]
        record_two = broker_accounts[1]
        if record_one.benefit_sponsors_broker_agency_profile_id == record_two.benefit_sponsors_broker_agency_profile_id && record_one.broker_agency_profile.market_kind == record_two.broker_agency_profile.market_kind
            record_one.destroy
        elsif record_one.broker_agency_profile.id != record_two.broker_agency_profile.id && record_one.broker_agency_profile.market_kind == record_two.broker_agency_profile.market_kind
          p " Person HBX ID #{fam.primary_family_member.person.hbx_id} had broker agency profile id: #{record_one.broker_agency_profile.id}, and broker agency profile id: #{record_two.broker_agency_profile.id} associated not duplicate"
        end
      end
    end
  end
end