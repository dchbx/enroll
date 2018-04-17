#rake migrate:employer_broker_profiles site_key=dc profile_type=employer_profile
#rake migrate:employer_broker_profiles site_key=dc profile_type=broker_profile

require 'csv'

namespace :migrate do
  desc "employer and broker_agency profiles, its organizations & roles migration"
  task :employer_broker_profiles => :environment do
    site_key = ENV['site_key']
    # profile_class = ENV['profile_class']
    profile_type = ENV['profile_type']

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/organizations_migration_status.csv"
    field_names = %w( organization_id fein hbx_id status)

    @logger = Logger.new("#{Rails.root}/log/migrations_data.log")
    @logger.info "Script Start #{TimeKeeper.datetime_of_record}"

    CSV.open(file_name, 'w') do |csv|
      csv << field_names
      #find or build site
      @site = find_site(site_key)

      #build and create GeneralOrganization and its profiles
      create_profile(profile_type, csv)

      @logger.info "End of the script" unless Rails.env.test?

    end
  end
end

def create_profile(profile_type, csv)

  old_organizations = get_old_organizations(profile_type)
  total_organizations = old_organizations.count
  offset_count = 0
  limit_count = 1000

  old_organizations.batch_size(limit_count).no_timeout.all.each do |old_org|
    begin
      if existing_new_organization(old_org).count == 0
        @old_profile = get_old_profile(old_org, profile_type)
        if profile_type == "employer_profile"
          json_data = @old_profile.to_json(:except => [:_id, :broker_agency_accounts, :plan_years, :sic_code, :updated_by_id, :workflow_state_transitions, :inbox, :documents])
          profile_class = "aca_shop_dc_employer_profile"
        elsif profile_type == "broker_profile"
          json_data = @old_profile.to_json(:except => [:_id, :aasm_state_set_on, :inbox, :documents])
          profile_class = "broker_agency_profile"
        end
        @old_profile_params = JSON.parse(json_data)
        @new_profile = initialize_new_profile(profile_class, old_org)
        new_organization = initialize_new_organization(old_org, profile_type)
        new_organization.save!
        csv << [old_org.id, old_org.fein, old_org.hbx_id, "success"]
        offset_count = offset_count + 1
      end
    rescue Exception => e
      @logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id} , #{e.backtrace}" unless Rails.env.test?
    end
  end
  @logger.info " #{offset_count} number of organizations processed at this point." unless Rails.env.test?
end

def get_old_organizations(profile_type)
  if profile_type == 'employer_profile'
    Organization.all_employer_profiles
  elsif profile_type == 'broker_profile'
    Organization.has_broker_agency_profile
  end
end

def get_old_profile(old_org, profile_type)
  if profile_type == "employer_profile"
    old_org.employer_profile
  elsif profile_type == "broker_profile"
    old_org.broker_agency_profile
  end
end

def existing_new_organization(old_org)
  BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id)
end

def initialize_new_profile(profile_class, old_org)
  new_profile = "BenefitSponsors::Organizations::#{profile_class.camelize}".constantize.new(@old_profile_params)
  new_profile.inbox.messages << @old_profile.inbox.messages
  new_profile.office_locations << old_org.office_locations

  #TODO  documents

  return new_profile
end

def initialize_new_organization(organization, profile_type)

  if profile_type == "employer_profile"
    json_data = organization.to_json(:except => [:_id, :version, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
    old_org_params = JSON.parse(json_data)
    general_organization = BenefitSponsors::Organizations::GeneralOrganization.new(old_org_params)
  elsif profile_type == "broker_profile"
    json_data = organization.to_json(:except => [:_id, :fein, :version, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
    old_org_params = JSON.parse(json_data)
    general_organization = BenefitSponsors::Organizations::ExemptOrganization.new(old_org_params)
  end

  general_organization.entity_kind = @old_profile.entity_kind.to_sym
  general_organization.site = @site
  general_organization.profiles << [@new_profile]
  return general_organization
end

def find_site(site_key)
  sites = BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  sites.present? ? sites.first : false
end