require File.join(Rails.root, "app", "data_migrations", "updating_broker_agency_account_or_profile")
# This rake task used to fix organization broker agency account and broker agency profile.
# RAILS_ENV=production bundle exec rake migrations:updating_broker_agency_account_or_profile fein=999900675 npn='61612' market_kind='both' defualt_general_agency_id='57339b79082e761cd1000066' legal_name='The Haney Company' address_1="308 Southwest Drive" address_2="", city="Silver Spring" state="MD" zip="20901" area_code="301" number="593-0600" action="create_org_and_broker_agency_profile"
# RAILS_ENV=production bundle exec rake migrations:updating_broker_agency_account_or_profile fein=999990069 address_1="308 Southwest Drive" address_2="", city="Silver Spring" state="MD" zip="20901" area_code="301" number="593-0600" action="create_primary_office_location_for_existing_org"
# RAILS_ENV=production bundle exec rake migrations:updating_broker_agency_account_or_profile org_fein='521565478 521696342 202025596' npn='61612' action="update_employer_broker_agency_accounts"
# RAILS_ENV=production bundle exec rake migrations:updating_broker_agency_account_or_profile npn='61612' action="update_family_broker_agency_accounts"
# RAILS_ENV=production bundle exec rake migrations:updating_broker_agency_account_or_profile npn='8417039' action="update_family_broker_agency_accounts"
# RAILS_ENV=production bundle exec rake migrations:updating_broker_agency_account_or_profile fein='8417039' hbx_id='1234' action="update_family_broker_agency_account_with_writing_agent"
namespace :migrations do
  desc "updating broker agency account and profile"
  UpdatingBrokerAgencyAccountOrProfile.define_task :updating_broker_agency_account_or_profile => :environment
end