class BrokerAgencyAccountsMigration < Mongoid::Migration
  def self.up
    new_organizations = BenefitSponsors::Organizations::Organization

    new_organizations.employer_profiles.each do |organization|

      #Migrate employer_profiles, broker_agency and benefit sponsorships before migrating broker agency accounts
      if organization.benefit_sponsorships.present?
        benefit_sponsorship = organization.benefit_sponsorships.where(:profile_id => organization.employer_profile.id)

        #collecting broker_agency_accounts for respective organization
        old_ep_org = Organization.all_employer_profiles.where(hbx_id: organization.hbx_id)
        old_ep_broker_agency_accounts = old_ep_org.first.employer_profile.broker_agency_accounts


        old_ep_broker_agency_accounts.each do |old_broker_agency_account|

          #querying old organization with old_broker_agency_account to get new orga with HBX_id
          old_bk_org = Organization.has_broker_agency_profile.where(:"broker_agency_profile._id" => BSON::ObjectId(old_broker_agency_account.broker_agency_profile_id))
          new_org = new_organizations.where(hbx_id: old_bk_org.first.hbx_id)

          json_data = old_broker_agency_account.to_json(:except => [:_id, :broker_agency_profile_id])
          broker_agency_account_params = JSON.parse(json_data)

          #creating broker_agency account in new model
          new_broker_agency_account = benefit_sponsorship.broker_agency_accounts.new(broker_agency_account_params)
          new_broker_agency_account.benefit_sponsors_broker_agency_profile_id = new_org.first.broker_agency_profile.id
          new_broker_agency_account.save!
        end

        benefit_sponsorship.save!
        organization.save!
      end
    end
  end

  def self.down
  end
end