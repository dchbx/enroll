require File.join Rails.root, "lib/mongoid_migration_task"

class UpdatingBrokerAgencyAccountOrProfile < MongoidMigrationTask

  def migrate
    action = ENV['action'].to_s
    case action
      when "create_org_and_broker_agency_profile"
        create_org_and_broker_agency_profile
      when "update_broker_role"
        update_broker_role
      when "create_primary_office_location_for_existing_org"
        create_primary_office_location_for_existing_org
      when "update_family_broker_agency_accounts"
        update_family_broker_agency_accounts
      when "update_employer_broker_agency_accounts"
        update_employer_broker_agency_account
      when "update_family_broker_agency_account_with_writing_agent"
        update_family_broker_agency_account_with_writing_agent
      else
        exit
    end
  end

  def create_org_and_broker_agency_profile
    org = Organization.where(:fein => ENV['fein']).first
    writing_agent= BrokerRole.by_npn(ENV['npn']).first

    if org.blank? && writing_agent.present?
      broker_agency_profile = BrokerAgencyProfile.new(market_kind: ENV['market_kind'],
                                                          entity_kind: "s_corporation",
                                                          primary_broker_role_id: writing_agent.id,
                                                          default_general_agency_profile_id: ENV['defualt_general_agency_id'])
      org = Organization.create(office_locations: [create_new_primary_office_location], fein: ENV['fein'], legal_name: ENV['legal_name'],
                                is_fake_fein: true, broker_agency_profile: broker_agency_profile)
      org.broker_agency_profile.approve!
      org.save!
      writing_agent.broker_agency_profile_id = broker_agency_profile.id
      writing_agent.save
      puts "Organization and BrokerAgencyProfile created" unless Rails.env.test?
    else
      puts "writing_agent not found" if !Rails.env.test?  && writing_agent.blank?
      puts "Organization exists with given fein" if !Rails.env.test? && org.present?
    end
  end

  def create_new_primary_office_location
    OfficeLocation.new(
        is_primary: true,
        address: {kind: "work", address_1: ENV['address_1'], address_2: ENV['address_2'], city: ENV['city'], state: ENV['state'], zip: ENV['zip'] },
        phone: {kind: "main", area_code: ENV['area_code'], number: ENV['number']}
    )
  end

  def create_primary_office_location_for_existing_org
    org = Organization.where(:fein => ENV['fein']).first

    if org.present?
    org.office_locations = [create_new_primary_office_location]
    org.save!
    puts "Office locations created for broker agency profile organization." unless Rails.env.test?
    else
      puts "Organization not found for #{ ENV['fein']}" unless Rails.env.test?
      # update_broker_role
    end
  end

  def update_broker_role
    writing_agent= BrokerRole.by_npn(ENV['npn']).first
    broker_agency_profile = BrokerAgencyProfile.find(ENV['broker_agency_profile_id'])

    if broker_agency_profile.present? && writing_agent.present?
      writing_agent.update_attributes!(:market_kind => ENV['market_kind'],broker_agency_profile_id: broker_agency_profile.id)
      puts "Updated broker's broker agency profile and market kind" unless Rails.env.test?
    elsif writing_agent.present? && ENV['broker_agency_profile_id'].present?
      writing_agent.update_attributes!(:market_kind => ENV['market_kind']) if ENV['market_kind'].present?
      writing_agent.update_attributes!(broker_agency_profile_id: ENV['broker_agency_profile_id']) if ENV['broker_agency_profile_id'].present?
      puts "Updated broker's broker agency profile and market kind" unless Rails.env.test?
    else
      puts "writing_agent not found" if !Rails.env.test?  && writing_agent.blank?
    end
  end

  def update_employer_broker_agency_account
    return "org fein not found" if ENV['org_fein'].blank? && !Rails.env.test?

    feins = ENV['org_fein'].split(' ').uniq
    writing_agent= BrokerRole.by_npn(ENV['npn']).first
    broker_agency_profile= writing_agent.broker_agency_profile

    if feins.present? && writing_agent.present? && broker_agency_profile.present?
      feins.each do |fein|
        org = Organization.where(:fein => fein).first
        broker_agency_account = org.employer_profile.broker_agency_accounts.where(:is_active => true).first
        if broker_agency_account.present?
          broker_agency_account.update_attributes!(broker_agency_profile_id:broker_agency_profile.id, writing_agent_id:writing_agent.id)
          puts "broker_agency_profile and writing_agent updated for broker_agency_account" unless Rails.env.test?
        else
          puts "No broker_agency_account found for organization fein:#{fein}" if !Rails.env.test?  && broker_agency_account.blank?
        end
      end
    else
      puts "writing_agent not found" if !Rails.env.test?  && writing_agent.blank?
      puts "broker_agency_profile not found for broker" if !Rails.env.test? && broker_agency_profile.blank?
    end
  end

  def update_family_broker_agency_accounts
    return "NPN not found" if ENV['npn'].blank? && !Rails.env.test?

    writing_agent= BrokerRole.by_npn(ENV['npn']).first
    broker_agency_profile= writing_agent.broker_agency_profile

    if writing_agent.present? && broker_agency_profile.present?
    Family.where(:broker_agency_accounts.exists=>true,:'broker_agency_accounts'=> {:$elemMatch => {:writing_agent_id=>BSON::ObjectId(writing_agent.id)}}).each do |fam|
      fam.broker_agency_accounts.unscoped.each do |agency_account|
        if agency_account.writing_agent_id == BSON::ObjectId(writing_agent.id)
          agency_account.update_attributes!(broker_agency_profile_id: broker_agency_profile.id)
          puts "updated broker agency profile for broker_agency_accounts" unless Rails.env.test?
        end
      end
    end
    else
      puts "writing_agent not found" if !Rails.env.test?  && writing_agent.blank?
      puts "broker_agency_profile not found for broker" if !Rails.env.test? && broker_agency_profile.blank?
    end
  end

  def update_family_broker_agency_account_with_writing_agent
    return "Fein not found" if ENV['org_fein'].blank?
    return "hbx_id not found" if ENV['hbx_id'].blank?

    broker_agency_profile = Organization.where(:fein => ENV['org_fein']).first.broker_agency_profile
    writing_agent = broker_agency_profile.primary_broker_role
    person = Person.where(hbx_id: ENV['hbx_id']).first

    if person.primary_family.present? && writing_agent.present? && broker_agency_profile.present?
      person.primary_family.broker_agency_accounts.unscoped.each do |agency_account|
        if agency_account.broker_agency_profile_id == BSON::ObjectId(broker_agency_profile.id)
          agency_account.update_attributes!(writing_agent_id: writing_agent.id)
          puts "updated writing_agent for broker_agency_accounts" unless Rails.env.test?
        end
      end
    else
      puts "broker_agency_profile not found for broker" if !Rails.env.test? && broker_agency_profile.blank?
      puts "writing_agent not found" if !Rails.env.test?  && writing_agent.blank?
      puts "person not found" if !Rails.env.test? && person.blank?
    end
  end
end