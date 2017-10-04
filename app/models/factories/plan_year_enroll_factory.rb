module Factories
  class PlanYearEnrollFactory

    attr_accessor :employer_profile, :start_on, :end_on, :benefit_group_ids, :missing_person, :missing_family

    def initialize
      @missing_person = 0
      @missing_family = 0
    end

    def enroll
      published_plan_years = @employer_profile.plan_years.where(:"start_on" => start_on).any_of([PlanYear.published.selector, PlanYear.renewing_published_state.selector])

      if published_plan_years.size == 0
        raise PlanYearPublishFactoryError, "Found zero Renewal/Published Plan Years for Employer #{@employer_profile.legal_name}"
      end

      if published_plan_years.size > 1
        raise PlanYearPublishFactoryError, "Found more than one Renewal/Published Plan Years for Employer #{@employer_profile.legal_name}"
      end

      @end_on = published_plan_years.first.end_on

      @count = 0
      @employer_profile.census_employees.each do |census_employee|
        begin
          census_employee.is_active? ? begin_employee_coverage(census_employee) : terminate_employee_coverage(census_employee)
          puts "Processed #{census_employee.full_name}"
        rescue Exception => e
          puts "Exception #{e.inspect} occured for #{census_employee.full_name}"
        end
      end

      puts "Processed #{@employer_profile.census_employees.count} census employees, skipped #{@count} census employee records"

      published_plan_years.each{ |plan_year| plan_year.activate! if plan_year.may_activate? }
      @employer_profile.plan_years.published.where(:start_on => (start_on - 1.year)).each do |plan_year|
        plan_year.expire!
      end

      benefit_groups = published_plan_years.first.benefit_groups

      enroll_employer_profile
      create_active_benefit_group_assignments(benefit_groups)
    end

    def create_active_benefit_group_assignments(benefit_groups)
      benefit_group_ids = benefit_groups.pluck(:_id)

      count = 0
      @employer_profile.census_employees.each do |census_employee|
        next unless census_employee.is_active?
        next if census_employee.active_benefit_group_assignment.present? && benefit_group_ids.include?(census_employee.active_benefit_group_assignment.benefit_group_id)
        if valid_bg_assignment = census_employee.benefit_group_assignments.renewing.detect{|bg_assignment| benefit_group_ids.include?(bg_assignment.benefit_group_id)}
          count += 1
          valid_bg_assignment.make_active
        end

        # if census_employee.benefit_group_assignments.none? {|bg_assignment| benefit_group_ids.include?(bg_assignment.benefit_group_id)}
        #   census_employee.add_benefit_group_assignment(benefit_groups.first, benefit_groups.first.start_on)
        # end
      end

      puts "Added benefit group assignments for #{count} employees!!"
    end

    def enroll_employer_profile
      if @employer_profile.may_enroll_employer?
        @employer_profile.enroll_employer!
      elsif @employer_profile.may_force_enroll?
        @employer_profile.force_enroll!
      end
    end

    def begin_employee_coverage(census_employee)
      person = match_person(census_employee)
      family = person.primary_family

      if family.blank?
        @count += 1
        @missing_family += 1
        raise PlanYearPublishFactoryError, "Family don't exist!!"
      end

      current_enrollments = family.active_household.hbx_enrollments.where(effective_on: (@start_on..@end_on)).shop_market

      enrolled_enrollments = current_enrollments.enrolled
      renewing_enrollments = current_enrollments.renewing + current_enrollments.where(:aasm_state.in => ["renewing_waived"])

      if enrolled_enrollments.size > 1 || renewing_enrollments.size > 1
        @count += 1 
        raise PlanYearPublishFactoryError, "More than one #{TimeKeeper.date_of_record.year} coverage found!!"
      end

      if enrolled_enrollments.size == 1 && renewing_enrollments.size == 1
        hbx_enrollment = enrolled_enrollments.first
        renewal_enrollment = renewing_enrollments.first

        if valid_enrollment?(hbx_enrollment, renewal_enrollment)
          hbx_enrollment.begin_coverage!
          hbx_enrollment.benefit_group_assignment.begin_benefit
          renewal_enrollment.cancel_coverage!
        else
          @count += 1
          raise PlanYearPublishFactoryError, "Hbx enrollment can't be enrolled updated_at #{hbx_enrollment.updated_at.strftime('%m-%d-%Y')}"
        end
      end

      renewing_enrollments.each do |hbx_enrollment|
        if hbx_enrollment.effective_on <= TimeKeeper.date_of_record
          hbx_enrollment.begin_coverage!
          hbx_enrollment.is_coverage_waived? ? hbx_enrollment.benefit_group_assignment.waive_benefit : hbx_enrollment.benefit_group_assignment.begin_benefit
        end
      end

      enrolled_enrollments.each do |hbx_enrollment|
        if hbx_enrollment.effective_on <= TimeKeeper.date_of_record
          hbx_enrollment.begin_coverage!
          hbx_enrollment.benefit_group_assignment.begin_benefit
        end
      end

      expire_previous_year_enrollments(family)
    end

    def valid_enrollment?(hbx_enrollment, renewal_enrollment)
      # Enable for 1/1 employers
      # hbx_enrollment.effective_on == renewal_enrollment.effective_on && hbx_enrollment.effective_on <= TimeKeeper.date_of_record && hbx_enrollment.updated_at < TimeKeeper.date_of_record.beginning_of_year
      hbx_enrollment.effective_on == renewal_enrollment.effective_on && hbx_enrollment.effective_on <= TimeKeeper.date_of_record
    end

    def terminate_employee_coverage(census_employee)
      return

      person = match_person(census_employee)
      family = person.primary_family

      return unless family.present?

      cancel_renewals(family)
      expire_previous_year_enrollments(family)
    end

    def waived_benefit_group_assignment(census_employee)
      @count = 0

      person = match_person(census_employee)
      if person.blank?
        return false
      end

      family = person.primary_family
      if family.blank?
        return false
      end

      enrollments = family.active_household.hbx_enrollments.where(effective_on: (@start_on..@end_on)).shop_market
      return false if enrollments.renewing.any?

      active_assignment = census_employee.active_benefit_group_assignment
      if active_assignment.blank?
        active_assignment = census_employee.benefit_group_assignments.detect{|assignment| @benefit_group_ids.include?(assignment.benefit_group_id) }
      end

      if enrollments.enrolled.any?
        active_assignment.begin_benefit
        return false
      end

      if enrollments.waived.any?
        if active_assignment.present?
          active_assignment.waive_benefit
          return true
        end
      end
      
      return false
    end

    private

    def match_person(census_employee)
      if census_employee.employee_role.blank?
        employee_relationship = Forms::EmployeeCandidate.new({
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
          ssn: census_employee.ssn,
          dob: census_employee.dob.strftime("%Y-%m-%d")
        })

        person = employee_relationship.match_person
        # if person.blank?
        #    person = Person.where({ :encrypted_ssn => Person.encrypt_ssn(census_employee.ssn) }).first
        # end

        if person.blank?
          @count += 1
          @missing_person += 1
          raise PlanYearPublishFactoryError, "No person match found!!"
        end
      else
        person = census_employee.employee_role.person
      end

      return person
    end
    
    # Question: Can we cancel other 2016 shop enrollments if any?
    def cancel_renewals(family)
      shop_enrollments = family.active_household.hbx_enrollments.shop_market.current_year

      (shop_enrollments.renewing + shop_enrollments.where(:aasm_state.in => ["renewing_waived"])).each do |hbx_enrollment|
        hbx_enrollment.cancel_coverage!
        hbx_enrollment.benefit_group_assignment.terminate_coverage! if hbx_enrollment.benefit_group_assignment.may_terminate_coverage?
        hbx_enrollment.benefit_group_assignment.update_attributes(is_active: false)
      end
    end

    def expire_previous_year_enrollments(family)
      prev_year_enrollments = family.active_household.hbx_enrollments.where(:"effective_on".lt => @start_on).shop_market
      prev_year_enrollments.enrolled.each do |hbx_enrollment|
        hbx_enrollment.expire_coverage! if hbx_enrollment.may_expire_coverage?
        benefit_group_assignment = hbx_enrollment.benefit_group_assignment
        benefit_group_assignment.expire_coverage! if benefit_group_assignment.may_expire_coverage?
        benefit_group_assignment.update_attributes(is_active: false) if benefit_group_assignment.is_active?
      end
    end
  end
   
  class PlanYearPublishFactoryError < StandardError; end
end

