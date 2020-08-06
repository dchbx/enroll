# frozen_string_literal: true

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

        existing_new_organizations = find_new_organization(old_org)
        @old_profile = old_org.broker_agency_profile
        json_data = @old_profile.to_json(:except => [:_id, :entity_kind, :aasm_state_set_on, :ach_routing_number, :ach_account_number, :inbox, :documents])
        old_profile_params = JSON.parse(json_data)

        @new_profile = self.initialize_new_profile(old_org, old_profile_params)

        raise "Duplicate organization exists" if existing_new_organizations.present? && existing_new_organizations.count > 1

        new_organization = if existing_new_organizations.present?
                             existing_new_organizations.first.profiles << @new_profile
                             existing_new_organizations.first
                           else
                             self.initialize_new_organization(old_org, site)
                           end

        BenefitSponsors::Organizations::Organization.skip_callback(:create, :after, :notify_on_create, raise: false)
        BenefitSponsors::Organizations::Organization.skip_callback(:update, :after, :notify_observers, raise: false)
        BenefitSponsors::Organizations::Profile.skip_callback(:save, :after, :publish_profile_event, raise: false)
        BenefitSponsors::Documents::Document.skip_callback(:create, :after, :notify_on_create, raise: false)

        if migrate_invalid_broker_hbx_id.include?(old_org.hbx_id)
          new_organization.save(validate: false)  # migrating invalid broker agency profiles.
        else
          raise Exception unless new_organization.valid?
          new_organization.save!
        end

        # build document for profile
        profile = existing_new_organizations.first.broker_agency_profile
        build_documents(old_org, profile)

        print '.' unless Rails.env.test?
        success += 1
      rescue Exception => e
        failed += 1
        print 'F' unless Rails.env.test?
        unless Rails.env.test?
          @logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
            validation_errors:
            organization - #{new_organization.errors.messages}
            profile - #{@new_profile.errors.messages},
            #{e.inspect}"
        end

      end
    end

    # TODO: issue broker & staff role ids: 18942185, 19773538, 19793505, 19927494
    say_with_time("Time taken to migrate broker staff roles and broker role") do
      Person.or({:broker_role.exists => true}, {:broker_agency_staff_roles.exists => true}).each do |person|
        person.broker_agency_staff_roles.unscoped.each do |staff|
          broker_agency_profile = old_broker_agency_profile(staff.broker_agency_profile_id.to_s)

          if broker_agency_profile.present?
            # TODO: refactor
            new_org = BenefitSponsors::Organizations::Organization.where(hbx_id: broker_agency_profile.hbx_id).first
            if new_org.present? && new_org.broker_agency_profile.present?
              staff.update_attributes(benefit_sponsors_broker_agency_profile_id: new_org.broker_agency_profile.id)
              print '.' unless Rails.env.test?
            else
              puts "New Organization Not Found for hbx_id:#{broker_agency_profile.hbx_id}"
            end
          else
            puts "Broker Agency Profile Not Found for Staff person hbx_id:#{staff.person.hbx_id}"
          end
        end

        next unless person.broker_role.present?
        broker_agency_profile = old_broker_agency_profile(person.broker_role.broker_agency_profile_id.to_s)
        if broker_agency_profile.present?
          # TODO: refactor
          new_org = BenefitSponsors::Organizations::Organization.where(hbx_id: broker_agency_profile.hbx_id).first
          if new_org.present? && new_org.broker_agency_profile.present?
            person.broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: new_org.broker_agency_profile.id)
            print '.' unless Rails.env.test?
          else
            puts "New Organization Not Found for hbx_id:#{broker_agency_profile.hbx_id}"
          end
        else
          puts "Broker Agency Profile Not Found for broker person hbx_id:#{person.hbx_id}"
        end
      end
    end
    @logger.info " Total #{total_organizations} old organizations for type: broker agency profile." unless Rails.env.test?
    @logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
    @logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
    @logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?

    BenefitSponsors::Organizations::Organization.set_callback(:create, :after, :notify_on_create, raise: false)
    BenefitSponsors::Organizations::Organization.set_callback(:update, :after, :notify_observers, raise: false)
    BenefitSponsors::Organizations::Profile.set_callback(:save, :after, :publish_profile_event, raise: false)
    BenefitSponsors::Documents::Document.set_callback(:create, :after, :notify_on_create, raise: false)

    true
  end

  def self.find_new_organization(old_org)
    BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id)
  end

  def self.initialize_new_profile(old_org, old_profile_params)
    new_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.new(old_profile_params)
    if old_org.broker_agency_profile.default_general_agency_profile_id.present?
      old_default_general_agency_profile_id = old_org.broker_agency_profile.default_general_agency_profile_id
      new_profile.default_general_agency_profile_id = new_general_agency_for_old_profile_id(old_default_general_agency_profile_id.to_s).id
    end
    build_inbox_messages(new_profile)
    build_office_locations(old_org, new_profile)
    new_profile
  end

  def self.build_documents(old_org, new_profile)
    @old_profile.documents.each do |document|
      next if BenefitSponsors::Documents::Document.where(id: document.id).present?
      doc = new_profile.documents.new(document.attributes.except("_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      doc.save!
    end

    old_org.documents.each do |document|
      next if BenefitSponsors::Documents::Document.where(id: document.id).present?
      doc = new_profile.documents.new(document.attributes.except("_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      doc.save!
    end
  end

  def self.build_inbox_messages(new_profile)
    @old_profile.inbox.messages.each do |message|
      msg = new_profile.inbox.messages.new(message.attributes.except("_id"))
      msg.body.gsub!("BrokerAgencyProfile", new_profile.class.to_s)
      msg.body.gsub!(@old_profile.id.to_s, new_profile.id.to_s)
    end
  end

  def self.build_office_locations(old_org, new_profile)
    old_org.office_locations.each do |office_location|
      new_office_location = new_profile.office_locations.new
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
    exempt_organization
  end

  def self.old_broker_agency_profile(id)
    Rails.cache.fetch("broker_agency_profile_#{id}", expires_in: 6.hour) do
      ::BrokerAgencyProfile.find(id)
    end
  end

  def self.new_broker_agency_for_old_profile_id(id)
    Rails.cache.fetch("new_broker_agency_#{id}", expires_in: 6.hour) do
      old_org = old_broker_agency_profile(id)
      BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id).first.broker_agency_profile
    end
  end

  def self.old_general_agency_profile(id)
    Rails.cache.fetch("general_agency_profile_#{id}", expires_in: 6.hour) do
      ::GeneralAgencyProfile.find(id)
    end
  end

  def self.new_general_agency_for_old_profile_id(id)
    Rails.cache.fetch("new_general_agency_#{id}", expires_in: 6.hour) do
      old_org = old_general_agency_profile(id)
      BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id).first.general_agency_profile
    end
  end

  def self.migrate_invalid_broker_hbx_id  # these organizations has no office locations
    ["ef19926553d4467598fe2d5927c54657", "65b6c4098e7c4b2bad0a0853313e331f"]
  end

  def self.find_site
    return @site if defined? @site
    @site = BenefitSponsors::Site.all.where(site_key: Settings.site.key.to_sym)
  end
end

