class CcaCarrierProfilesMigration < Mongoid::Migration
  def self.up

    if Settings.site.key.to_s == "cca"
    site_key = "cca"

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/carrier_profile_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
    field_names = %w( organization_id benefit_sponsor_organization_id status)

    logger = Logger.new("#{Rails.root}/log/carrier_profile_migration_data.log") unless Rails.env.test?
    logger.info "Script Start for carrier_profile_#{TimeKeeper.datetime_of_record}" unless Rails.env.test?

    CSV.open(file_name, 'w') do |csv|
      csv << field_names

      #build and create Organization and its profiles
      status = create_profile(site_key, csv, logger)

      if status
        puts "Rake Task execution completed, check carrier_profile_migration_data logs & carrier_profile_migration_status csv for additional information." unless Rails.env.test?
      else
        puts "Script execution failed" unless Rails.env.test?
      end
    end

    logger.info "End of the script for carrier_profile" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
    raise "Can not be reversed!"
  end

  private

  def self.create_profile(site_key, csv, logger)

    #find or build site
    sites = self.find_site(site_key)
    return false unless sites.present?
    site = sites.first

    #get main app organizations for migration
    old_organizations = Organization.unscoped.exists("carrier_profile" => true)

    #counters
    total_organizations = old_organizations.count
    existing_organization = 0
    success =0
    failed = 0
    limit_count = 1000

    say_with_time("Time taken to migrate organizations") do
      old_organizations.batch_size(limit_count).no_timeout.all.each do |old_org|
        begin
          existing_new_organizations = find_new_organization(old_org)
          if existing_new_organizations.count == 0
            @old_profile = old_org.carrier_profile

            json_data = @old_profile.to_json(:except => [:_id, :updated_by_id])
            old_profile_params = JSON.parse(json_data)

            @new_profile = self.initialize_new_profile(old_org, old_profile_params)
            # @new_profile.issuer_hios_ids << @old_profile.issuer_hios_ids

            new_organization = self.initialize_new_organization(old_org, site)
            new_organization.save!

            csv << [old_org.id, new_organization.id, "Migration Success"]
            success = success + 1
          else
            existing_organization = existing_organization + 1
            csv << [old_org.id, existing_new_organizations.first.id, "Already Migrated to new model, no action taken"]
          end
        rescue Exception => e
          failed = failed + 1
          csv << [old_org.id, "0", "Migration Failed"]
          logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id} , #{e.inspect}" unless Rails.env.test?
        end
      end
    end
    logger.info " Total #{total_organizations} old organizations for type: carrier profile." unless Rails.env.test?
    logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?
    return true
  end

  def self.find_new_organization(old_org)
    BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id)
  end

  def self.initialize_new_profile(old_org, old_profile_params)
    new_profile = BenefitSponsors::Organizations::IssuerProfile.new(old_profile_params)

    build_documents(old_org, new_profile)
    build_office_locations(old_org, new_profile)
    return new_profile
  end

  def self.build_documents(old_org, new_profile)
    old_org.documents.each do |document|
      doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier"))
      doc.identifier = document.identifier if document.identifier.present?
      doc.save!
    end
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

  def self.initialize_new_organization(organization, site)
    json_data = organization.to_json(:except => [:_id, :updated_by_id, :issuer_assigned_id, :versions, :version, :fein, :employer_profile, :broker_agency_profile, :general_agency_profile, :carrier_profile, :hbx_profile, :office_locations, :is_fake_fein, :home_page, :is_active, :updated_by, :documents])
    old_org_params = JSON.parse(json_data)
    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.new(old_org_params)
    exempt_organization.site = site
    exempt_organization.profiles << [@new_profile]
    return exempt_organization
  end

  def self.find_site(site_key)
    BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  end
end
