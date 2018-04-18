#rake migrate:employer_broker_profiles site_key=dc profile_type=employer_profile
#rake migrate:employer_broker_profiles site_key=dc profile_type=broker_profile

require 'csv'

namespace :migrate do
  desc "employer and broker_agency profiles, its organizations & roles migration"
  task :employer_broker_profiles => :environment do
    site_key = ENV['site_key']
    profile_type = ENV['profile_type']

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/organizations_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
    field_names = %w( organization_id hbx_id status)

    @logger = Logger.new("#{Rails.root}/log/organizations_migration_data.log")
    @logger.info "Script Start #{TimeKeeper.datetime_of_record}"

    CSV.open(file_name, 'w') do |csv|
      csv << field_names
      #find or build site
      @site = find_site(site_key)

      #build and create GeneralOrganization and its profiles
      status = create_profile(profile_type, csv)
      if status
        puts "Rake Task execution completed, check organizations_migration_data logs & organizations_migration_status csv for additional information." unless Rails.env.test?
      else
        @logger.info "Check if the inputed ENV values are valid" unless Rails.env.test?
        puts "Rake Task execution failed for given input" unless Rails.env.test?
      end
      @logger.info "End of the script" unless Rails.env.test?
    end
  end
end

def create_profile(profile_type, csv)
  old_organizations = get_old_organizations(profile_type)
  return false unless old_organizations.present?
  total_organizations = old_organizations.count
  existing_organization = 0
  success =0
  failed = 0
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
        old_profile_params = JSON.parse(json_data)
        @new_profile = initialize_new_profile(profile_class, old_org, old_profile_params)
        new_organization = initialize_new_organization(old_org, profile_type)
        new_organization.save!
        csv << [old_org.id, old_org.hbx_id, "Migration Success"]
        success = success + 1
      else
        existing_organization = existing_organization + 1
        csv << [old_org.id, old_org.hbx_id, "Already Migrated to new model, no action taken"]
      end
    rescue Exception => e
      failed = failed + 1
      csv << [old_org.id, old_org.hbx_id, "Migration Failed"]
      @logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id} , #{e.inspect}" unless Rails.env.test?
    end
  end
  @logger.info " There are Total #{total_organizations} old organizations for type: #{profile_type}." unless Rails.env.test?
  @logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
  @logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
  @logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?
  return true
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

def initialize_new_profile(profile_class, old_org, old_profile_params)
  new_profile = "BenefitSponsors::Organizations::#{profile_class.camelize}".constantize.new(old_profile_params)
  build_inbox_messages(new_profile)
  build_documents(old_org, new_profile)
  build_office_locations(old_org, new_profile)

  return new_profile
end

def build_inbox_messages(new_profile)
  @old_profile.inbox.messages.each do |message|
    new_profile.inbox.messages.new(message.attributes.except("_id"))
  end
end

def build_documents(old_org, new_profile)
  @old_profile.documents.each do |document|
    new_profile.documents.new(document.attributes.except("_id"))
  end

  old_org.documents.each do |document|
    new_profile.documents.new(document.attributes.except("_id"))
  end
end

def build_office_locations(old_org, new_profile)
  old_org.office_locations.each do |office_location|
    new_office_location = new_profile.office_locations.new()
    new_office_location.is_primary = office_location.is_primary
    address_params = office_location.address.attributes.except("_id")
    phone_params = office_location.phone.attributes.except("_id")
    new_office_location.address = address_params
    new_office_location.phone = phone_params
  end
end

def initialize_new_organization(organization, profile_type)
  if profile_type == "employer_profile"
    json_data = organization.to_json(:except => [:_id, :updated_by_id, :version, :versions, :employer_profile, :office_locations, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
    old_org_params = JSON.parse(json_data)
    general_organization = BenefitSponsors::Organizations::GeneralOrganization.new(old_org_params)
  elsif profile_type == "broker_profile"
    json_data = organization.to_json(:except => [:_id, :updated_by_id, :version, :versions, :fein, :broker_agency_profile, :office_locations, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
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