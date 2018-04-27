require 'csv'

namespace :migrations do
  desc "profiles, its organizations migration"
  task :account_migration => :environment do

    new_organizations = BenefitSponsors::Organizations::Organization

    new_organizations.employer_profiles.each do |organization|
      if organization.benefit_sponsorships.present?
        benefit_sponsorship = organization.benefit_sponsorships.new(:profile_id => organization.employer_profile.id)

        old_ep_org = Organization.all_employer_profiles.where(hbx_id: organization.hbx_id)
        old_ep_broker_agency_accounts = old_ep_org.first.employer_profile.broker_agency_accounts

        old_ep_broker_agency_accounts.each do |old_broker_agency_account|

          old_bk_orgs = Organization.has_broker_agency_profile
          old_bk_org = old_bk_orgs.where(:"broker_agency_profile._id" => BSON::ObjectId(old_broker_agency_account.broker_agency_profile_id))
          new_org = new_organizations.where(hbx_id: old_bk_org.first.hbx_id)

          json_data = old_broker_agency_account.to_json(:except => [:_id, :broker_agency_profile_id])
          broker_agency_account_params = JSON.parse(json_data)

          new_broker_agency_account = benefit_sponsorship.broker_agency_accounts.new(broker_agency_account_params)
          new_broker_agency_account.broker_agency_profile_id = new_org.first.broker_agency_profile.id
          new_broker_agency_account.save!
        end

        #TODO for benefit markets
        benefit_sponsorship.save!
        organization.save!
      end
    end
  end
end