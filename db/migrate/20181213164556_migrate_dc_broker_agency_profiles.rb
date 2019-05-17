class MigrateDcBrokerAgencyProfiles < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"
      @logger = Logger.new("#{Rails.root}/log/broker_profile_migration_data.log") unless Rails.env.test?
      @logger.info "Script Start for broker_profile_#{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      status = create_profile  #build and create Organization and its profiles

      if status
        puts "" unless Rails.env.test?
        puts "Check broker_agency_profiles_migration_data logs & broker_agency_profiles_migration_status csv for additional information." unless Rails.env.test?
      else
        puts "" unless Rails.env.test?
        puts "Script execution failed" unless Rails.env.test?
      end
      @logger.info "End of the script for broker_profile" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
    if Settings.site.key.to_s == "dc"
      BenefitSponsors::Organizations::Organization.broker_agency_profiles.delete_all
    else
      say("Skipping migration for non-DC site")
    end
  end

  def self.create_profile

    return false unless find_site.present?
    site = find_site.first

    #get main app organizations for migration
    old_organizations = Organization.unscoped.exists(:broker_agency_profile => true)

    #counters
    total_organizations = old_organizations.count
    existing_organization = 0
    success = 0
    failed = 0
    limit_count = 1000

    say_with_time("Time taken to migrate organizations") do
      old_organizations.batch_size(limit_count).no_timeout.all.each do |old_org|
        begin
          existing_new_organizations = find_new_organization(old_org)
          if existing_new_organizations.count == 0
            @old_profile = old_org.broker_agency_profile
            json_data = @old_profile.to_json(:except => [:_id, :entity_kind, :aasm_state_set_on, :ach_routing_number, :ach_account_number, :inbox, :documents])
            old_profile_params = JSON.parse(json_data)

            @new_profile = self.initialize_new_profile(old_org, old_profile_params)

            raise "Duplicate organization exists" if existing_new_organizations.present? && existing_new_organizations.count > 1

            new_organization = if existing_new_organizations.present?
                                 organization = existing_new_organizations.first
                                 organization.profiles << @new_profile
                                 organization
                               else
                                 self.initialize_new_organization(old_org, site)
                               end

            raise Exception unless new_organization.valid?
            BenefitSponsors::Organizations::Organization.skip_callback(:create, :after, :notify_on_create, raise: false)
            BenefitSponsors::Organizations::Organization.skip_callback(:update, :after, :notify_observers, raise: false)
            BenefitSponsors::Organizations::Profile.skip_callback(:save, :after, :publish_profile_event, raise: false)
            new_organization.save!

            #Roles Migration
            person_records_with_old_staff_roles = find_staff_roles
            link_existing_staff_roles_to_new_profile( person_records_with_old_staff_roles)

            print '.' unless Rails.env.test?
            success = success + 1
          end
        rescue Exception => e
          failed = failed + 1
          print 'F' unless Rails.env.test?
          @logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
          validation_errors:
          organization - #{new_organization.errors.messages}
          profile - #{@new_profile.errors.messages},
          #{e.inspect}" unless Rails.env.test?
        end
      end
    end
    @logger.info " Total #{total_organizations} old organizations for type: broker agency profile." unless Rails.env.test?
    @logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
    @logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
    @logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?
    return true
  end

  def self.find_new_organization(old_org)
    BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id)
  end

  def self.initialize_new_profile(old_org, old_profile_params)
    new_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.new(old_profile_params)

    build_documents(old_org, new_profile)
    build_inbox_messages(new_profile)
    build_office_locations(old_org, new_profile)
    return new_profile
  end

  def self.build_documents(old_org, new_profile)

    @old_profile.documents.each do |document|
      doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      doc.save!
    end

    old_org.documents.each do |document|
      doc = new_profile.documents.new(document.attributes.except("_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      doc.save!
    end
  end

  def self.build_inbox_messages(new_profile)
    @old_profile.inbox.messages.each do |message|
      msg = new_profile.inbox.messages.new(message.attributes.except("_id"))
      msg.body.gsub!("BrokerAgencyProfile", "BenefitSponsorsBrokerAgencyProfile")
      msg.body.gsub!(@old_profile.id.to_s, new_profile.id.to_s)
    end
  end

  def self.build_office_locations(old_org, new_profile)
    old_org.office_locations.each do |office_location|
      new_office_location = new_profile.office_locations.new()
      new_office_location.is_primary = office_location.is_primary
      address_params = office_location.address.attributes.except("_id") if office_location.address.present?
      phone_params = office_location.phone.attributes.except("_id") if office_location.phone.present?
      new_office_location.address = address_params
      new_office_location.phone = phone_params
    end
  end

  def self.initialize_new_organization(organization, site)
    json_data = organization.to_json(:except => [:_id, :updated_by_id, :issuer_assigned_id, :version, :versions, :employer_profile, :broker_agency_profile, :general_agency_profile, :carrier_profile, :hbx_profile, :office_locations, :is_fake_fein, :is_active, :updated_by, :documents])

    old_org_params = JSON.parse(json_data)
    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.new(old_org_params)
    exempt_organization.entity_kind = @old_profile.entity_kind.to_sym
    exempt_organization.site = site
    exempt_organization.profiles << [@new_profile]
    return exempt_organization
  end

  def self.find_staff_roles
    Person.or({:"broker_role.broker_agency_profile_id" => @old_profile.id},
              {:"broker_agency_staff_roles.broker_agency_profile_id" => @old_profile.id})
  end

  def self.link_existing_staff_roles_to_new_profile( person_records_with_old_staff_roles)
    person_records_with_old_staff_roles.each do |person|

      old_broker_role = person.broker_role
      old_broker_agency_staff_role = person.broker_agency_staff_roles.where(broker_agency_profile_id: @old_profile.id).first

      old_broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: @new_profile.id) if old_broker_role.present?
      old_broker_agency_staff_role.update_attributes(benefit_sponsors_broker_agency_profile_id: @new_profile.id) if old_broker_agency_staff_role.present?
    end
  end

  def self.find_site
    return @site if defined? @site
    @site =  BenefitSponsors::Site.all.where(site_key: Settings.site.key.to_sym)
  end
end

