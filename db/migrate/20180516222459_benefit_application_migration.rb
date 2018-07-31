class BenefitApplicationMigration < Mongoid::Migration

  def self.up
    if Settings.site.key.to_s == "cca"

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/benefit_application_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      field_names = %w(organization_name organization_fein plan_year_id plan_year_start_on status)

      logger = Logger.new("#{Rails.root}/log/benefit_application_migration.log")
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      CSV.open(file_name, 'w') do |csv|
        csv << field_names
        migrate_plan_years_to_benefit_applications(csv, logger)

        puts "" unless Rails.env.test?
        puts "Check the report and logs for futher information" unless Rails.env.test?

      end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  private

  def self.migrate_plan_years_to_benefit_applications(csv, logger)

    old_organizations = Organization.unscoped.exists(:"employer_profile.plan_years" => true)

    success = 0
    failed = 0
    total_plan_years = 0
    limit = 100

    say_with_time("Time take to migrate plan years") do
      old_organizations.batch_size(limit).no_timeout.each do |old_org|

        unless new_org(old_org).present?
          print 'F' unless Rails.env.test?
          csv << [old_org.legal_name, old_org.fein, '', '', "New organization not found for fein: #{old_org.fein}"]
          next
        end

        new_organization = new_org(old_org)

        benefit_sponsorship = new_organization.first.active_benefit_sponsorship
        self.set_benefit_sponsorship_state(old_org, benefit_sponsorship)
        benefit_sponsorship.registered_on = old_org.employer_profile.registered_on
        benefit_sponsorship.effective_begin_on = self.get_benefit_sponsorship_effective_on(old_org)
        construct_workflow_state_for_benefit_sponsorship(benefit_sponsorship, old_org)
        BenefitSponsors::BenefitSponsorships::BenefitSponsorship.skip_callback(:save, :after, :notify_on_save)
        benefit_sponsorship.save

        old_org.employer_profile.plan_years.asc(:start_on).each do |plan_year|

          total_plan_years += 1

          @benefit_package_map = {}
          begin
            benefit_application = convert_plan_year_to_benefit_application(benefit_sponsorship, plan_year,csv)
            next unless benefit_application

            plan_year_plan_hios_ids = self.get_plan_hios_ids_of_plan_year(plan_year)
            benfit_application_product_hios_ids = self.get_plan_hios_ids_of_benefit_application(benefit_application)

            unless self.new_benfit_application_product_valid(plan_year_plan_hios_ids, benfit_application_product_hios_ids)
              if self.tufts_case(plan_year_plan_hios_ids, benfit_application_product_hios_ids, plan_year.start_on.year)
                self.update_sponsor_catalog_product_package(@benefit_sponsor_catalog, plan_year)
                @benefit_sponsor_catalog.save
              else
                print 'F' unless Rails.env.test?
                csv << [old_org.legal_name, old_org.fein, plan_year.id, plan_year.start_on, "benefit application products mismatch with old model plan year products"]
                next
              end
            end

            if benefit_application.valid? && self.new_benfit_application_product_valid(self.get_plan_hios_ids_of_plan_year(plan_year), self.get_plan_hios_ids_of_benefit_application(benefit_application))
              BenefitSponsors::BenefitApplications::BenefitApplication.skip_callback(:save, :after, :notify_on_save)
              benefit_application.save!
              assign_employee_benefits(benefit_sponsorship)
              print '.' unless Rails.env.test?
              csv << [old_org.legal_name, old_org.fein, plan_year.id, plan_year.start_on, 'Success']
              success += 1
            else
              raise StandardError, benefit_application.errors.to_s
            end
          rescue Exception => e
            print 'F' unless Rails.env.test?
            csv << [old_org.legal_name, old_org.fein, plan_year.id, plan_year.start_on, 'Failed', e.to_s]
            failed += 1
          end
        end
      end

      logger.info " Total #{old_organizations.count} old organizations with plan years" unless Rails.env.test?
      logger.info " Total #{total_plan_years} plan years" unless Rails.env.test?
      logger.info " #{failed} plan years failed to migrate into new DB at this point." unless Rails.env.test?
      logger.info " #{success} plan years successfully migrated into new DB at this point." unless Rails.env.test?
    end
  end

  # TODO: Verify updated by field on plan year
  # "updated_by_id"=>BSON::ObjectId('5909e07d082e766d68000078'),
  def self.convert_plan_year_to_benefit_application(benefit_sponsorship, plan_year, csv)
    py_attrs = plan_year.attributes.except(:benefit_groups, :workflow_state_transitions)
    application_attrs = py_attrs.slice(:fte_count, :pte_count, :msp_count, :created_at, :updated_at, :terminated_on)

    benefit_application = benefit_sponsorship.benefit_applications.new(application_attrs)
    benefit_application.effective_period = (plan_year.start_on..plan_year.end_on)
    benefit_application.write_attribute(:effective_period, (plan_year.start_on..plan_year.end_on)) if plan_year.start_on == plan_year.end_on  # benefit_application.effective_period setter method setting value to nil if plan_year.start_on == plan_year.end_on for those cases uses below
    benefit_application.open_enrollment_period = (plan_year.open_enrollment_start_on..plan_year.open_enrollment_end_on)
    benefit_application.pull_benefit_sponsorship_attributes
    predecessor_application = benefit_sponsorship.benefit_applications.where(:"effective_period.max" => benefit_application.effective_period.min.to_date.prev_day, :aasm_state.in=> [:active, :terminated, :expired, :imported])

    if predecessor_application.present?
      if predecessor_application.count < 2
        benefit_application.predecessor_id = predecessor_application.first.id
      elsif predecessor_application.where(:"effective_period.max" => Date.new(2018,7,31)).count == 2  # exception case for 8/1 conversion
        benefit_application.predecessor_id = predecessor_application.where(aasm_state: :imported).first.id
      else
        benefit_application.predecessor_id = predecessor_application.first.id
      end
    end

    @benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.resolve_service_areas, benefit_application.effective_period.min)
    catalog_product_hios_id = self.benefit_sponsor_catalog_products(@benefit_sponsor_catalog, plan_year)
    plan_year_plan_hios_ids = self.get_plan_hios_ids_of_plan_year(plan_year)

    unless self.new_benefit_sponsor_catalog_product_valid(catalog_product_hios_id, plan_year_plan_hios_ids)
      self.update_sponsor_catalog_product_package(@benefit_sponsor_catalog, plan_year)
    end

    @benefit_sponsor_catalog.benefit_application = benefit_application
    @benefit_sponsor_catalog.save
    benefit_application.benefit_sponsor_catalog = @benefit_sponsor_catalog

    # TODO: do unscoped...to pick all the benefit groups
    plan_year.benefit_groups.unscoped.each do |benefit_group|
      params = sanitize_benefit_group_attrs(benefit_group)
      importer = BenefitSponsors::Importers::BenefitPackageImporter.call(benefit_application, params)
      if importer.benefit_package.blank?
        raise Standard, "Benefit Package creation failed"
      end
      @benefit_package_map[benefit_group] = importer.benefit_package
      self.set_predecessor_for_benefit_package(benefit_application, importer.benefit_package)
    end

    benefit_application.aasm_state = benefit_application.matching_state_for(plan_year)

    if plan_year.is_conversion
      benefit_application.aasm_state = :imported
    end

    construct_workflow_state_transitions(benefit_application, plan_year)
    benefit_application
  end

  def self.is_plan_year_effectuated?(plan_year)
    %w(published enrolling enrolled active suspended expired terminated termination_pending renewing_draft renewing_published renewing_enrolling renewing_enrolled renewing_publish_pending).include?(plan_year.aasm_state)
  end

  def self.continuous_coverage?(old_org)
    return true if old_org.employer_profile.plan_years.count < 2
    return true unless old_org.employer_profile.plan_years.any?{|py| py.expired? || py.terminated? || py.active?}
    plan_years = old_org.employer_profile.plan_years.select {|plan_year| is_plan_year_effectuated?(plan_year)}.sort_by(&:start_on)
    if plan_years.each_cons(2).any? {|plan_year| plan_year[0].end_on.next_day !=  plan_year[1].start_on }
      return false
    else
      return true
    end
  end

  def self.get_benefit_sponsorship_effective_on(old_org)
    plan_years = old_org.employer_profile.plan_years.asc(:start_on).where(:aasm_state.in=> [:active, :terminated, :expired])
    if plan_years.present?
      plan_years.first.start_on
    else
      return nil
    end
  end

  def self.get_plan_hios_ids_of_plan_year(plan_year)
    plan_year.benefit_groups.inject([]) do |plan_hios_ids, benefit_group|
      plan_hios_ids += benefit_group.elected_plans.map(&:hios_id)
      plan_hios_ids += [benefit_group.reference_plan.hios_id]
      plan_hios_ids.uniq
    end
  end

  def self.get_plan_hios_ids_of_benefit_application(benefit_application)
    benefit_application.benefit_packages.inject([]) do |product_hios_ids, benefit_package|
      product_hios_ids += benefit_package.health_sponsored_benefit.products(benefit_application.effective_period.min).map(&:hios_id)
      product_hios_ids += [benefit_package.health_sponsored_benefit.reference_product.hios_id]
      product_hios_ids.uniq
    end
  end

  def self.new_benfit_application_product_valid(plan_year_plan_hios_ids, benfit_application_product_hios_ids)
    return false unless (benfit_application_product_hios_ids.size == plan_year_plan_hios_ids.size)
    (benfit_application_product_hios_ids & plan_year_plan_hios_ids).size == benfit_application_product_hios_ids.size
  end

  def self.benefit_sponsor_catalog_products(benefit_sponsor_catalog, plan_year)
    @package_kind = plan_year.benefit_groups.map{|benfit_group| self.map_product_package_kind(benfit_group.plan_option_kind)}
    benefit_sponsor_catalog.product_packages.select{|product_package| @package_kind.include?(product_package.package_kind)}.inject([]) do |catalog_product, product_package|
      catalog_product += product_package.products.map(&:hios_id)
    end
  end

  def self.new_benefit_sponsor_catalog_product_valid(catalog_product_hios_id, plan_year_plan_hios_ids)
    plan_year_plan_hios_ids.all? {|hios_id| catalog_product_hios_id.include?(hios_id)}
  end

  def self.update_sponsor_catalog_product_package(benefit_sponsor_catalog, plan_year)
    plan_year.benefit_groups.each do |benefit_group|
      plans = benefit_group.elected_plans
      products =  plans.inject([]) do |product, plan|
        product += BenefitMarkets::Products::Product.where(hios_id: plan.hios_id).select {|product| product.active_year == plan.active_year }
      end
      package_kind = self.map_product_package_kind(benefit_group.plan_option_kind)
      product_package = benefit_sponsor_catalog.product_packages.where(package_kind: package_kind).first
      product_package.products = products
    end
  end

  def self.tufts_case(plan_hios, product_hios, year)
    tufts_exists_in_plan_year = Plan.where(:"hios_id".in=>plan_hios, active_year: year).select{|product| product.carrier_profile.legal_name == "Tufts Health Direct"}
    tufts_exists_in_benefit_application = BenefitMarkets::Products::Product.where(:'hios_id'.in=>product_hios).select{|product| ((product.issuer_profile.legal_name == "Tufts Health Direct") && (product.active_year == year))}
    if tufts_exists_in_plan_year.blank? && tufts_exists_in_benefit_application.present?
      return true
    else
      return false
    end
  end

  def self.set_predecessor_for_benefit_package(benefit_application, benefit_package)
    return unless benefit_application.predecessor_id.present?
    predecessor_application = benefit_application.predecessor
    predecessor_benefit_packages = benefit_application.predecessor.benefit_packages

    if predecessor_benefit_packages.count < 2
      benefit_package.predecessor_id  = benefit_application.predecessor.benefit_packages.first.id
      return
    end

    new_package_hios_id = benefit_package.health_sponsored_benefit.products(benefit_application.effective_period.min).map(&:hios_id)
    predecessor_benefit_packages.each do |predecessor_package|
      predecessor_package_hios_id = predecessor_package.health_sponsored_benefit.products(predecessor_application.effective_period.min).map(&:hios_id)
      if ((new_package_hios_id.size == predecessor_package_hios_id.size) && ((new_package_hios_id && predecessor_package_hios_id).size == new_package_hios_id.size))
        benefit_package.predecessor_id  = predecessor_package.id
      end
    end
  end

  def self.map_product_package_kind(plan_option_kind)
    package_kind_mapping = {
        sole_source: :single_product,
        single_plan: :single_product,
        single_carrier: :single_issuer,
        metal_level: :metal_level
    }

    package_kind_mapping[plan_option_kind.to_sym]
  end

  def self.sanitize_benefit_group_attrs(benefit_group)
    attributes = benefit_group.attributes.slice(
        :title, :description, :created_at, :updated_at, :is_active, :effective_on_kind, :effective_on_offset,
        :plan_option_kind, :relationship_benefits, :dental_relationship_benefits
    )

    attributes[:is_default] = benefit_group.default
    attributes[:reference_plan_hios_id] = benefit_group.reference_plan.hios_id
    attributes[:dental_reference_plan_hios_id] = benefit_group.dental_reference_plan.hios_id if benefit_group.is_offering_dental?
    attributes[:composite_tier_contributions] = benefit_group.composite_tier_contributions.inject([]) do |contributions, tier|
      contributions << {
          relationship: tier.composite_rating_tier,
          offered: tier.offered,
          premium_pct: tier.employer_contribution_percent,
          estimated_tier_premium: tier.estimated_tier_premium,
          final_tier_premium: tier.final_tier_premium
      }
    end
    attributes
  end

  def self.construct_workflow_state_transitions(benefit_application, plan_year)
    plan_year.workflow_state_transitions.unscoped.asc(:transition_at).each do |wst|
      attributes = wst.attributes.except(:_id)
      attributes[:from_state] = benefit_application.send(:plan_year_to_benefit_application_states_map)[wst.from_state.to_sym]
      attributes[:to_state] = benefit_application.send(:plan_year_to_benefit_application_states_map)[wst.to_state.to_sym]
      benefit_application.workflow_state_transitions.build(attributes)
    end
  end


  def self.set_benefit_sponsorship_state(old_org, benefit_sponsorship)

    if ["conversion", "mid_plan_year_conversion"].include?(benefit_sponsorship.source_kind.to_s)
       benefit_sponsorship.aasm_state = :active
      return
    end

    if benefit_sponsorship.source_kind.to_s == "self_serve"

      if old_org.employer_profile.active_plan_year.present?
        benefit_sponsorship.aasm_state = :active
        return
      end

      if old_org.employer_profile.published_plan_year.present? && old_org.employer_profile.published_plan_year.enrolling?
        benefit_sponsorship.aasm_state = :initial_enrollment_open
      else
        benefit_sponsorship.aasm_state = benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[old_org.employer_profile.aasm_state.to_sym]
      end
    end
  end

  def self.construct_workflow_state_for_benefit_sponsorship(benefit_sponsorship, old_org)
    old_org.employer_profile.workflow_state_transitions.unscoped.asc(:transition_at).each do |wst|
      attributes = wst.attributes.except(:_id)
      attributes[:from_state] = benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[wst.from_state.to_sym]
      attributes[:to_state] = benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[wst.to_state.to_sym]
      benefit_sponsorship.workflow_state_transitions.build(attributes)
    end
  end

  def self.assign_employee_benefits(benefit_sponsorship)
    @benefit_package_map.each do |benefit_group, benefit_package|
      benefit_group.census_employees.unscoped.each do |census_employee|
        if census_employee.benefit_sponsorship_id.blank?
          census_employee.employee_role.update_attributes(benefit_sponsors_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) if census_employee.employee_role && census_employee.employee_role.benefit_sponsors_employer_profile_id.blank?
          census_employee.benefit_sponsors_employer_profile_id = benefit_sponsorship.organization.employer_profile.id if census_employee.benefit_sponsors_employer_profile_id.blank?
          census_employee.benefit_sponsorship = benefit_sponsorship
        end

        census_employee.benefit_group_assignments.unscoped.each do |benefit_group_assignment|
          if benefit_group_assignment.benefit_group_id.to_s == benefit_group.id.to_s
            benefit_group_assignment.benefit_package_id = benefit_package.id
          end
        end
        CensusEmployee.skip_callback(:save, :after, :assign_default_benefit_package)
        CensusEmployee.skip_callback(:save, :after, :assign_benefit_packages)
        CensusEmployee.skip_callback(:save, :after, :construct_employee_role)
        CensusEmployee.skip_callback(:update, :after, :update_hbx_enrollment_effective_on_by_hired_on)
        census_employee.save(:validate => false)
      end
    end
  end

  def self.new_org(old_org)
    BenefitSponsors::Organizations::Organization.where(fein: old_org.fein)
  end
end