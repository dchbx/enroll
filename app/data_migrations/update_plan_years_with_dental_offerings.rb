require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdatePlanYearsWithDentalOfferings < MongoidMigrationTask

  def migrate
    month = ENV['calender_month']
    @passive_renewals = []
    start_on = Date.new(TimeKeeper.date_of_record.year, month.to_i, 1)
    puts "Processing Groups for #{start_on.strftime('%m/%d/%Y')}" unless Rails.env.test?

    organizations = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => prev_year_query(start_on)})
    organizations.each do |org|
      plan_year = org.employer_profile.plan_years.where(prev_year_query(start_on)).first
      if plan_year.benefit_groups.any?{|bg| bg.is_offering_dental? }
        begin
          current_plan_year = org.employer_profile.plan_years.where(current_year_query(start_on)).first

          if current_plan_year.blank?
            raise "missing renewal plan year."
          end

          if plan_year.benefit_groups.any?{|bg| matching_benefit_group(current_plan_year, bg).blank?}
            raise "non matching benefit groups."
          end

          if current_plan_year.benefit_groups.any?{|bg| bg.is_offering_dental? }
            puts "Employer: #{org.legal_name}(#{org.fein}) already have Dental Offerings."
          else
            add_dental_offerings(current_plan_year, plan_year)
          end

          trigger_dental_passive_renewals(current_plan_year, plan_year)
        rescue Exception => e
          puts "Employer: #{org.legal_name}(#{org.fein}) #{e.to_s}"
        end
      end
    end

    puts @passive_renewals.inspect unless Rails.env.test?
  end

  def add_dental_offerings(target_plan_year, source_plan_year)
    source_plan_year.benefit_groups.each do |benefit_group|
      raise "Dental renewal plan missing!" if benefit_group.dental_reference_plan.renewal_plan.blank?

      target_benefit_group = matching_benefit_group(target_plan_year, benefit_group)
      target_benefit_group.dental_plan_option_kind  = benefit_group.dental_plan_option_kind
      target_benefit_group.dental_reference_plan_id = benefit_group.dental_reference_plan.renewal_plan_id
      target_benefit_group.elected_dental_plan_ids  = benefit_group.renewal_elected_dental_plan_ids
      target_benefit_group.dental_relationship_benefits = benefit_group.dental_relationship_benefits
      
      employer = source_plan_year.employer_profile
      if target_benefit_group.save
        puts "Employer: #{employer.legal_name}(#{employer.fein}) updated with dental offerings." unless Rails.env.test?
      else
        raise "FAILED: Unable to update Employer: #{employer.legal_name}(#{employer.fein}) with Dental Offerings."
      end
    end
  end

  def trigger_dental_passive_renewals(renewing_plan_year, active_plan_year)
    employer = renewing_plan_year.employer_profile

    if %w(renewing_enrolling renewing_enrolled active).include?(renewing_plan_year.aasm_state.to_s)
      employer.census_employees.non_terminated.each do |ce|
        person = Person.where(encrypted_ssn: Person.encrypt_ssn(ce.ssn)).first
        
        if person.blank?
          employee_role, family = Factories::EnrollmentFactory.add_employee_role({
            first_name: ce.first_name,
            last_name: ce.last_name,
            ssn: ce.ssn, 
            dob: ce.dob,
            employer_profile: employer,
            gender: ce.gender,
            hired_on: ce.hired_on
            })
          puts "created family for #{ce.full_name}"
        else
          family = person.primary_family
        end

        if family.present? && dental_renewals(family, renewing_plan_year).blank?
          factory = Factories::FamilyEnrollmentRenewalFactory.new
          factory.family = family
          factory.census_employee = ce
          factory.employer = employer
          factory.renewing_plan_year = renewing_plan_year
          factory.active_plan_year = active_plan_year
          factory.disable_notifications = true
          factory.process_renewals_for('dental')

          family.reload
          family.active_household.hbx_enrollments.shop_market.where({
            :coverage_kind => 'dental', 
            :benefit_group_id.in => renewing_plan_year.benefit_groups.pluck(:_id),
            :aasm_state.in => ['auto_renewing', 'renewing_waived']
            }).each do |hbx_enrollment|
            if hbx_enrollment.effective_on <= TimeKeeper.date_of_record
              @passive_renewals << hbx_enrollment.hbx_id if hbx_enrollment.auto_renewing?
              hbx_enrollment.begin_coverage! if hbx_enrollment.may_begin_coverage?
            end
          end

          puts "Passively renewed #{ce.full_name}" unless Rails.env.test?
        else
          puts "Family missing for #{ce.full_name}" if family.blank?
        end
      end
    else
      puts "Employer: #{employer.legal_name}(#{employer.fein}) is under #{renewing_plan_year.aasm_state} state."
    end
  end

  def dental_renewals(family, renewing_plan_year)
    family.active_household.hbx_enrollments.where({
      :benefit_group_id.in => renewing_plan_year.benefit_groups.pluck(:_id),
      :aasm_state.in => ['auto_renewing', 'renewing_waived', 'inactive', 'coverage_selected', 'coverage_enrolled', 'coverage_terminated'],
      :coverage_kind => 'dental',
      :effective_on => renewing_plan_year.start_on
    })
  end

  private

  def prev_year_query(start_on)
    {
      :start_on => start_on.prev_year, 
      :aasm_state.in => PlanYear::PUBLISHED + ['expired']
    }
  end

  def current_year_query(start_on)
    {
      :start_on => start_on, 
      :aasm_state.in => (PlanYear::PUBLISHED + PlanYear::RENEWING)
    }
  end

  def matching_benefit_group(target_plan_year, benefit_group)
    target_plan_year.benefit_groups.detect{|bg| bg.plan_option_kind == benefit_group.plan_option_kind && bg.elected_plan_ids == benefit_group.renewal_elected_plan_ids}
  end
end