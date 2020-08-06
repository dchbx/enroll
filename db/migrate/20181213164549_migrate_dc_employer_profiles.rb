# frozen_string_literal: true

class MigrateDcEmployerProfiles < Mongoid::Migration
  def self.up
    # TODO: do we need to set rating and service area on benefit_sponsorship --> rating & service area not needed on benefit sponsorship
    # TODO check registerd on date feild  --> benefit sponsorship
    # TODO check congress Organization & employer profiles --> ??
    # TODO foreign_embassy_or_consulate entity kind organization-??
    # TODO do we need to set fein for exempt organization  --> adding fein

    if Settings.site.key.to_s == "dc"
      site_key = "dc"

      logger = Logger.new("#{Rails.root}/log/employer_profiles_migration_data.log") unless Rails.env.test?
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      status = create_profile(site_key, logger)

      if status
        puts "" unless Rails.env.test?
        puts "Check employer_profiles_migration_data logs & employer_profiles_migration_status csv for additional information." unless Rails.env.test?
      else
        puts "" unless Rails.env.test?
        puts "Script execution failed" unless Rails.env.test?
      end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
    if Settings.site.key.to_s == "dc"
      BenefitSponsors::Organizations::Organization.employer_profiles.delete_all
    else
      say("Skipping migration for non-DC site")
    end
  end

  private

  def self.create_profile(site_key, logger)
    sites = find_site(site_key)
    return false unless sites.present?
    site = sites.first

    old_organizations = Organization.unscoped.exists(:employer_profile => true)
    total_organizations = old_organizations.count
    existing_organization = 0
    success = 0
    failed = 0
    limit_count = 1000

    say_with_time("Time taken to create benefit sposonsorship") do
      Organization.collection.aggregate([
        {"$match" => {"employer_profile" => { "$exists" => true }}},
        {"$project" => {"hbx_id" => 1, "employer_profile.profile_source" => 1,
                        "employer_profile.no_ssn" => 1, "employer_profile.enable_ssn_date" => 1,
                        "employer_profile.disable_ssn_date" => 1, "employer_profile.broker_agency_accounts" => 1,
                        "employer_profile.registered_on" => 1,"employer_profile.plan_years" => 1}},

        {"$unwind" => {"path": "$employer_profile.plan_years", "preserveNullAndEmptyArrays": true}},

        {"$project" => {
          "hbx_id" => 1, 'employer_profile.profile_source' => 1, "employer_profile.registered_on" => 1,
          "employer_profile.no_ssn" => 1, "employer_profile.enable_ssn_date" => 1, "employer_profile.disable_ssn_date" => 1,
          "employer_profile.broker_agency_accounts" => { "$ifNull" => ["$employer_profile.broker_agency_accounts", []]},
          "benefit_application" => {"fte_count" => "$employer_profile.plan_years.fte_count",
                                    "_id" => "$employer_profile.plan_years._id",
                                    "pte_count" => "$employer_profile.plan_years.pte_count",
                                    "msp_count" => "$employer_profile.plan_years.msp_count",
                                    "created_at" => "$employer_profile.plan_years.created_at",
                                    "updated_at" => "$employer_profile.plan_years.updated_at",
                                    "terminated_on" => "$employer_profile.plan_years.terminated_on",
                                    "termination_kind" => "$employer_profile.plan_years.termination_kind",
                                    "aasm_state" => '$employer_profile.plan_years.aasm_state',
                                    "effective_period" => { "min": "$employer_profile.plan_years.start_on","max": "$employer_profile.plan_years.end_on" },
                                    "open_enrollment_period" => { "min": "$employer_profile.plan_years.open_enrollment_start_on","max": "$employer_profile.plan_years.open_enrollment_end_on" }}
        }},
        {"$group" => {"_id" => "$_id","hbx_id" => {"$last" => "$hbx_id"},
                      "source_kind" => {"$last" => "$employer_profile.profile_source"},
                      "registered_on" => {"$last" => "$employer_profile.registered_on"},
                      "is_no_ssn_enabled" => {"$last" => "$employer_profile.no_ssn"},
                      "ssn_enabled_on" => {"$last" => "$employer_profile.enable_ssn_date"},
                      "ssn_disabled_on" => {"$last" => "$employer_profile.disable_ssn_date"},
                      "broker_agency_accounts" => {"$last" => "$employer_profile.broker_agency_accounts"},
                      "benefit_applications" => {"$push" => {"$cond" => { if: { "$ne": ["$benefit_application.effective_period", {}]},
                                                                          then: "$benefit_application", else: []}}}}},
        {"$out" => "benefit_sponsors_benefit_sponsorships_benefit_sponsorships"}
]).each
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.collection.update_many({:benefit_applications => [[]]}, {"$unset" => {"benefit_applications" => []}})
      BenefitSponsors::BenefitSponsorships::BenefitSponsorship.collection.update_many({:broker_agency_accounts => []}, {"$unset" => {"broker_agency_accounts" => 1 }})
    end

    say_with_time("Time taken to migrate organizations") do
      old_organizations.batch_size(limit_count).no_timeout.each do |old_org|

        existing_new_organizations = find_new_organization(old_org)
        if existing_new_organizations.count == 0
          @old_profile = old_org.employer_profile

          json_data = @old_profile.to_json(:except => [:_id, :no_ssn, :enable_ssn_date, :disable_ssn_date, :sic_code, :xml_transmitted_timestamp, :entity_kind, :profile_source, :aasm_state, :registered_on, :contact_method, :employer_attestation, :broker_agency_accounts, :general_agency_accounts, :employer_profile_account, :plan_years, :updated_by_id, :workflow_state_transitions, :inbox, :documents])
          old_profile_params = JSON.parse(json_data)

          @new_profile = initialize_new_profile(old_org, old_profile_params)
          new_organization = initialize_new_organization(old_org, site)
          market = is_congress?(old_org) ? fehb_benefit_market : benefit_market

          @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(hbx_id: old_org.hbx_id).first
          @benefit_sponsorship.profile_id = @new_profile.id
          @benefit_sponsorship.benefit_market = market
          @benefit_sponsorship.source_kind = @old_profile.profile_source.to_sym
          @benefit_sponsorship.organization_id = new_organization.id
          @benefit_sponsorship.unset(:hbx_id)
          @benefit_sponsorship.send(:generate_hbx_id)

          migrate_employer_profile_account
          set_benefit_sponsorship_state
          set_benefit_sponsorship_effective_on
          construct_workflow_state_for_benefit_sponsorship

          #raise Exception unless @benefit_sponsorship.valid?
          BenefitSponsors::BenefitSponsorships::BenefitSponsorship.skip_callback(:save, :after, :notify_on_save, raise: false)
          BenefitSponsors::BenefitSponsorships::BenefitSponsorship.skip_callback(:create, :before, :generate_hbx_id, raise: false)
          @benefit_sponsorship.save(validate: false)

          raise Exception unless new_organization.valid?
          BenefitSponsors::Organizations::Organization.skip_callback(:create, :after, :notify_on_create, raise: false)
          BenefitSponsors::Organizations::Profile.skip_callback(:save, :after, :publish_profile_event, raise: false)
          new_organization.save!

          #employer staff roles migration
          person_records_with_old_staff_roles = find_staff_roles
          link_existing_staff_roles_to_new_profile(person_records_with_old_staff_roles)

          #employee roles migration
          person_records_with_old_employee_roles = find_employee_roles
          link_existing_employee_roles_to_new_profile(person_records_with_old_employee_roles)

          #census employees migration
          census_employees_with_old_id = find_census_employees
          link_existing_census_employees_to_new_profile(census_employees_with_old_id)

          print '.' unless Rails.env.test?
          success += 1
        end
      rescue Exception => e
        failed += 1
        print 'F' unless Rails.env.test?
        unless Rails.env.test?
          logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
            validation_errors:
            organization - #{new_organization.errors.messages}
            profile - #{@new_profile.errors.messages},
            benefit_sponsorship - #{@benefit_sponsorship.errors.messages},
            #{e.inspect}"
        end

      end
    end

    say_with_time("Time taken to update all census employee record to default value.") do
      mark_all_census_as_enroll
    end

    say_with_time("Time taken create bill file") do
      create_bill_file
    end

    logger.info " Total #{total_organizations} old organizations for type: employer profile" unless Rails.env.test?
    logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?

    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.set_callback(:save, :after, :notify_on_save, raise: false)
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.set_callback(:create, :before, :generate_hbx_id, raise: false)
    BenefitSponsors::Organizations::Organization.set_callback(:create, :after, :notify_on_create, raise: false)
    BenefitSponsors::Organizations::Profile.set_callback(:save, :after, :publish_profile_event, raise: false)

    true
  end

  def self.find_new_organization(old_org)
    BenefitSponsors::Organizations::Organization.where(fein: old_org.fein)
  end

  def self.initialize_new_profile(old_org, old_profile_params)
    profile_class = is_congress?(old_org) ? BenefitSponsors::Organizations::FehbEmployerProfile : BenefitSponsors::Organizations::AcaShopDcEmployerProfile
    new_profile = profile_class.new(old_profile_params)

    if @old_profile.contact_method == "Only Electronic communications"
      new_profile.contact_method = :electronic_only
    elsif @old_profile.contact_method == "Paper and Electronic communications"
      new_profile.contact_method = :paper_and_electronic
    elsif @old_profile.contact_method == "Only Paper communication"
      new_profile.contact_method = :paper_only
    end

    build_office_locations(old_org, new_profile)
    new_profile
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
    org_class = is_congress?(organization) || is_exempt_org?(organization) ? BenefitSponsors::Organizations::ExemptOrganization : BenefitSponsors::Organizations::GeneralOrganization
    general_organization = org_class.new(old_org_params)
    general_organization.entity_kind = @old_profile.entity_kind.to_sym
    general_organization.site = site
    general_organization.profiles << [@new_profile]
    general_organization
  end

  def self.find_staff_roles
    Person.where(:employer_staff_roles => {
                   '$elemMatch' => {employer_profile_id: @old_profile.id}
                 })
  end

  def self.link_existing_staff_roles_to_new_profile(person_records_with_old_staff_roles)
    person_records_with_old_staff_roles.each do |person|
      person.employer_staff_roles.where(employer_profile_id: @old_profile.id).update_all(benefit_sponsor_employer_profile_id: @new_profile.id)
    end
  end

  def self.find_employee_roles
    Person.where(:"employee_roles.employer_profile_id" => @old_profile.id)
  end

  def self.link_existing_employee_roles_to_new_profile(person_records_with_old_employee_roles)
    person_records_with_old_employee_roles.each do |person|
      person.employee_roles.where(employer_profile_id: @old_profile.id).update_all(benefit_sponsors_employer_profile_id: @new_profile.id)
    end
  end

  def self.find_census_employees
    CensusEmployee.unscoped.where(employer_profile_id: @old_profile.id)
  end

  def self.link_existing_census_employees_to_new_profile(census_employees_with_old_id)
    census_employees_with_old_id.update_all(benefit_sponsors_employer_profile_id: @new_profile.id, benefit_sponsorship_id: @benefit_sponsorship.id)
  end

  def self.mark_all_census_as_enroll # by default to enroll in DC
    CensusEmployee.unscoped.all.update_all(expected_selection: 'enroll')
  end

  def self.is_congress?(organization)
    ["100101", "118510", "100102"].include?(organization.hbx_id)
  end

  def self.is_exempt_org?(organization)
    ['governmental_employer','foreign_embassy_or_consulate'].include?(organization.employer_profile.entity_kind)
  end

  def self.set_benefit_sponsorship_state
    @benefit_sponsorship.aasm_state = @benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[@old_profile.aasm_state.to_sym]
  end

  def self.migrate_employer_profile_account
    return unless @old_profile.employer_profile_account.present?
    benefit_account = @benefit_sponsorship.build_benefit_sponsorship_account(@old_profile.employer_profile_account.attributes.except("_id","updated_by_id","current_statement_activity","workflow_state_transitions","premium_payments"))

    @old_profile.employer_profile_account.current_statement_activity.each do |activity|
      benefit_account.current_statement_activities.new(activity.attributes.except("_id"))
    end

    @old_profile.employer_profile_account.premium_payments.each do |payment|
      benefit_account.financial_transactions.new(payment.attributes.except("_id"))
    end
  end

  def self.create_bill_file
    BillFile.all.each do |bill_file|
      BenefitSponsors::BenefitSponsorships::BillFile.create(bill_file.attributes.except("_id"))
    end
  end

  def self.set_benefit_sponsorship_effective_on
    effective_begin_on = (@old_profile.plan_years.asc(:start_on).first.start_on if @old_profile.plan_years.present?)
    @benefit_sponsorship.effective_begin_on = effective_begin_on
  end

  def self.construct_workflow_state_for_benefit_sponsorship
    @old_profile.workflow_state_transitions.unscoped.asc(:transition_at).each do |wst|
      attributes = wst.attributes.except(:_id)
      attributes[:from_state] = @benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[wst.from_state.to_sym]
      attributes[:to_state] = @benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[wst.to_state.to_sym]
      @benefit_sponsorship.workflow_state_transitions.build(attributes)
    end
  end

  def self.find_site(site_key)
    return @site if defined? @site
    @site = BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  end

  def self.benefit_market
    return @benefit_market if defined? @benefit_market
    @benefit_market = find_site('dc').first.benefit_market_for(:aca_shop)
  end

  def self.fehb_benefit_market
    return @fehb_benefit_market if defined? @fehb_benefit_market
    @fehb_benefit_market = find_site('dc').first.benefit_market_for(:fehb)
  end
end
