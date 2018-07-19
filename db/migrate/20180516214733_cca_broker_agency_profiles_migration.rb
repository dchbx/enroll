class CcaBrokerAgencyProfilesMigration < Mongoid::Migration
  def self.up

    if Settings.site.key.to_s == "cca"
      site_key = "cca"

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/cca_broker_profile_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      field_names = %w( legal_name hbx_id new_organization_id  total_roles status)

      logger = Logger.new("#{Rails.root}/log/cca_broker_profile_migration_data.log") unless Rails.env.test?
      logger.info "Script Start for broker_profile_#{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      CSV.open(file_name, 'w') do |csv|
        csv << field_names

        #build and create Organization and its profiles
        status = create_profile(site_key, csv, logger)

        if status
          puts "" unless Rails.env.test?
          puts "Check cca broker_agency_profiles_migration_data logs & broker_agency_profiles_migration_status csv for additional information." unless Rails.env.test?
        else
          puts "" unless Rails.env.test?
          puts "Script execution failed" unless Rails.env.test?
        end
      end

      logger.info "End of the script for broker_profile" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  private

  def self.create_profile(site_key, csv, logger)

    #find or build site
    sites = self.find_site(site_key)
    return false unless sites.present?
    site = sites.first

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

            json_data = @old_profile.to_json(:except => [:_id, :entity_kind, :aasm_state_set_on, :inbox, :documents])
            old_profile_params = JSON.parse(json_data)

            @new_profile = self.initialize_new_profile(old_org, old_profile_params)
            new_organization = self.initialize_new_organization(old_org, site)

            raise Exception unless new_organization.valid?
            BenefitSponsors::Organizations::Organization.skip_callback(:create, :after, :notify_on_create)
            new_organization.save!

            #Roles Migration
            person_records_with_old_staff_roles = find_staff_roles
            link_existing_staff_roles_to_new_profile( person_records_with_old_staff_roles)


            print '.' unless Rails.env.test?
            csv << [old_org.legal_name, old_org.hbx_id, new_organization.id, person_records_with_old_staff_roles.count , "Migration Success"]
            success = success + 1
          else
            existing_organization = existing_organization + 1
            csv << [old_org.legal_name, old_org.hbx_id, existing_new_organizations.first.id, "-" , "Already Migrated to new model, no action taken"]
          end
        rescue Exception => e
          failed = failed + 1
          print 'F' unless Rails.env.test?
          csv << [old_org.legal_name, old_org.hbx_id, "0", "-","Migration Failed"]
          logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
          validation_errors:
          organization - #{new_organization.errors.messages}
          profile - #{@new_profile.errors.messages},
          #{e.inspect}" unless Rails.env.test?
        end
      end
    end
    logger.info " Total #{total_organizations} old organizations for type: broker agency profile." unless Rails.env.test?
    logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?
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
      BenefitSponsors::Documents::Document.skip_callback(:save, :after, :notify_on_save)
      doc.save!
    end

    old_org.documents.each do |document|
      doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      BenefitSponsors::Documents::Document.skip_callback(:save, :after, :notify_on_save)
      doc.save!
    end
  end

  def self.build_inbox_messages(new_profile)
    @old_profile.inbox.messages.each do |message|
      msg = new_profile.inbox.messages.new(message.attributes.except("_id"))
      msg.body.gsub!("BrokerAgencyProfile", "BenefitSponsorsBrokerAgencyProfile")
      msg.body.gsub!(@old_profile.id.to_s, new_profile.id.to_s)

      new_profile.documents.where(subject: "notice").each do |doc|
        old_emp_docs = @old_profile.documents.where(identifier: doc.identifier)
        old_org_docs = @old_profile.organization.documents.where(identifier: doc.identifier)
        old_document_id = if old_emp_docs.present?
                            old_emp_docs.first.id.to_s
                          elsif old_org_docs.present?
                            old_org_docs.first.id.to_s
                          end
        msg.body.gsub!(old_document_id, doc.id.to_s) if (doc.id.to_s.present? && old_document_id.present?)
      end

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
    json_data = organization.to_json(:except => [:_id, :updated_by_id, :issuer_assigned_id, :version, :versions, :fein, :broker_agency_profile, :office_locations, :is_fake_fein, :is_active, :updated_by, :documents])
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

      old_broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: @new_profile.id)
      old_broker_agency_staff_role.update_attributes(benefit_sponsors_broker_agency_profile_id: @new_profile.id) if old_broker_agency_staff_role.present?
    end
  end

  def self.find_site(site_key)
    BenefitSponsors::Site.all.where(site_key: site_key.to_sym) if site_key.present?
  end
end
