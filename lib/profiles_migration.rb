module ProfilesMigration

  def self.create_profile(site_key, profile_type, csv, logger)

    #find or build site
    sites = self.find_site(site_key)
    return false unless sites.present?
    site = sites.first

    #get main app organizations for migration
    old_organizations = get_old_organizations(profile_type)
    return false unless old_organizations.present?

    #counters
    total_organizations = old_organizations.count
    existing_organization = 0
    success =0
    failed = 0
    limit_count = 1000

    old_organizations.batch_size(limit_count).no_timeout.all.each do |old_org|
      begin
        if self.existing_new_organization(old_org).count == 0
          @old_profile = get_old_profile(old_org, profile_type)

          if profile_type == "employer_profile"
            json_data = @old_profile.to_json(:except => [:_id, :broker_agency_accounts, :general_agency_accounts, :employer_profile_account, :plan_years, :sic_code, :updated_by_id, :workflow_state_transitions, :inbox, :documents])
            profile_class = "aca_shop_dc_employer_profile"
          elsif profile_type == "broker_agency_profile"
            json_data = @old_profile.to_json(:except => [:_id, :aasm_state_set_on, :inbox, :documents])
            profile_class = "broker_agency_profile"
          elsif (profile_type == "carrier_profile")
            json_data = @old_profile.to_json(:except => [:_id, :updated_by_id])
            profile_class = "issuer_profile"
          end

          old_profile_params = JSON.parse(json_data)

          @new_profile = self.initialize_new_profile(profile_type, profile_class, old_org, old_profile_params)
          new_organization = self.initialize_new_organization(old_org, site, profile_type)
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
        logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id} , #{e.inspect}" unless Rails.env.test?
      end
    end
    logger.info " Total #{total_organizations} old organizations for type: #{profile_type}." unless Rails.env.test?
    logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?
    return true
  end

  def self.get_old_organizations(profile_type)
    Organization.unscoped.exists("#{profile_type}".to_sym => true)
  end

  def self.get_old_profile(old_org, profile_type)
    if old_org.respond_to?(profile_type) && %w[employer_profile broker_agency_profile carrier_profile].include?(profile_type)
      old_org.public_send(profile_type)
    end
  end

  def self.existing_new_organization(old_org)
    BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id)
  end

  def self.initialize_new_profile(profile_type, profile_class, old_org, old_profile_params)
    new_profile = "BenefitSponsors::Organizations::#{profile_class.camelize}".constantize.new(old_profile_params)

    build_inbox_messages(new_profile) if (profile_type =="employer_profile" || profile_type =="broker_agency_profile")
    build_documents(old_org, new_profile)
    build_office_locations(old_org, new_profile)
    return new_profile
  end

  def self.build_inbox_messages(new_profile)
    @old_profile.inbox.messages.each do |message|
      new_profile.inbox.messages.new(message.attributes.except("_id"))
    end
  end

  def self.build_documents(old_org, new_profile)
    old_org.documents.each do |document|
      new_profile.documents.new(document.attributes.except("_id"))
    end
    #
  end

  def self.build_office_locations(old_org, new_profile)
    old_org.office_locations.each do |office_location|
      new_office_location = new_profile.office_locations.new()
      new_office_location.is_primary = office_location.is_primary
      address_params = office_location.address.attributes.except("_id")
      phone_params = office_location.phone.attributes.except("_id")
      new_office_location.address = address_params
      new_office_location.phone = phone_params
    end
  end

  def self.initialize_new_organization(organization, site, profile_type)

    if profile_type == "employer_profile"
      json_data = organization.to_json(:except => [:_id, :updated_by_id, :version, :versions, :employer_profile, :office_locations, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
      orga_class = "general_organization"
    elsif profile_type == "broker_agency_profile"
      json_data = organization.to_json(:except => [:_id, :updated_by_id, :version, :versions, :fein, :broker_agency_profile, :office_locations, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
      orga_class = "exempt_organization"
    elsif (profile_type == "carrier_profile")
      json_data = organization.to_json(:except => [:_id, :updated_by_id, :version, :versions, :fein, :carrier_profile, :office_locations, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
      orga_class = "exempt_organization"
    end

    old_org_params = JSON.parse(json_data)
    general_organization = "BenefitSponsors::Organizations::#{orga_class.camelize}".constantize.new(old_org_params)
    general_organization.entity_kind = @old_profile.entity_kind.to_sym if (profile_type =="employer_profile" || profile_type =="broker_agency_profile" || profile_type =="hbx_profile")
    general_organization.site = site
    general_organization.profiles << [@new_profile]
    return general_organization
  end

  def self.find_site(site_key)
    BenefitSponsors::Site.all.where(site_key: site_key.to_sym)  if site_key.present?
  end
end