#rake migrate:employer_broker_profiles site_key=dc profile_type=employer_profile profile_class=aca_shop_dc_employer_profile
#rake migrate:employer_broker_profiles site_key=dc profile_type=broker_agency_profile profile_class=broker_agency_profile

require 'csv'

namespace :migrate do
  desc "employer and broker_agency profiles, its organizations & roles migration"
  task :employer_broker_profiles => :environment do
    site_key = ENV['site_key']
    profile_class = ENV['profile_class']
    profile_type = ENV['profile_type']

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/organizations_migration_status.csv"
    field_names = %w( organization_id fein hbx_id status)

    # @logger = Logger.new("#{Rails.root}/log/data_set.log")
    # @logger.info "Script Start #{TimeKeeper.datetime_of_record}"

    CSV.open(file_name, 'w') do |csv|
      csv << field_names
      #find or build site
      @site = find_site(site_key)

      #build and create GeneralOrganization and its profiles
      create_profile(profile_type, profile_class, csv)

      #TODO
      #link profiles accounts - link created new employer profiles with created new broker agenacy profiles
      # broker_agency_accounts - ******
      # general_agency_accounts - *****
      # employer_profile_account - needs research wheather DC/ MA have data to migrate
    end
  end
end

def create_profile(profile_type, profile_class, csv)

  old_organizations = get_old_organizations(profile_type)
  old_organizations.batch_size(1000).no_timeout.all.each do |old_org|

    if existing_general_organization(old_org).count == 0
      @old_profile = get_old_profile(old_org, profile_type)

      if profile_type == "broker_agency_profile"
        json_data = old_profile.to_json(:except => [:_id, :aasm_state_set_on, :inbox, :documents])
      elsif profile_type == "employer_profile"
        json_data = old_profile.to_json(:except => [:_id, :broker_agency_accounts, :plan_years, :sic_code, :workflow_state_transitions, :inbox, :documents])
      end

      @old_profile_params = JSON.parse(json_data)
      @new_profile = initialize_new_profile(profile_class)

      #TODO
      #Documents -- currently new model has embed many documents from organizations,
      #but old model has embed many documents from organization and profiles
      # FEIN is fake for all broker profiles , change the migration 

      general_organization = initialize_general_organization(old_org)
      general_organization.save!

      csv << [old_org.id, old_org.fein, old_org.hbx_id, "success"]
    end
  end
end

def get_old_organizations(profile_type)
  if profile_type == 'employer_profile'
    Organization.all_employer_profiles
  elsif profile_type == 'broker_agency_profile'
    Organization.has_broker_agency_profile
  end
end

def get_old_profile(old_org, profile_type)
  if profile_type == "employer_profile"
    old_org.employer_profile
  elsif profile_type == "broker_agency_profile"
    old_org.broker_agency_profile
  end
end

def existing_general_organization(old_org)
  BenefitSponsors::Organizations::GeneralOrganization.where(fein: old_org.fein)
end

def initialize_new_profile(profile_class)
  new_profile = "BenefitSponsors::Organizations::#{profile_class.camelize}".constantize.new(@old_profile_params)
  new_profile.inbox.messages << old_profile.inbox.messages
  new_profile.office_locations << old_org.office_locations
  return new_profile
end

def initialize_general_organization(organization)
  json_data = organization.to_json(:except => [:_id, :version, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
  old_org_params = JSON.parse(json_data)
  general_organization = BenefitSponsors::Organizations::GeneralOrganization.new(old_org_params)
  general_organization.entity_kind = @old_profile.entity_kind.to_sym
  general_organization.site = @site
  general_organization.profiles << [@new_profile]
  return general_organization
end

def find_site(site_key)
  sites = BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  sites.present? ? sites.first : false
end