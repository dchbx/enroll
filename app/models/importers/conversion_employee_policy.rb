module Importers
  class ConversionEmployeePolicy < ConversionEmployeePolicyCommon

    # validate :validate_benefit_group_assignment
    validate :validate_census_employee
    validate :validate_fein
    validate :validate_plan
    validates_length_of :fein, is: 9
    validates_length_of :subscriber_ssn, is: 9
    validates_presence_of :hios_id

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      end
    end

    def validate_census_employee
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      if found_employee.nil?
        errors.add(:subscriber_ssn, "no census employee found")
      end
    end

    def validate_benefit_group_assignment
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      return true unless find_employee
      found_bga = find_benefit_group_assignment
      if found_bga.nil?
        errors.add(:subscriber_ssn, "no benefit group assignment found")
      end
    end

    def validate_plan
      return true if hios_id.blank?
      found_plan = find_plan
      if found_plan.nil?
        errors.add(:hios_id, "no plan found with hios_id #{hios_id} and active year #{plan_year}")
      end
    end

    def find_employee
      return @found_employee unless @found_employee.nil?
      return nil if subscriber_ssn.blank?
      found_employer = find_employer
      return nil if found_employer.nil?
      candidate_employees = CensusEmployee.where({
        employer_profile_id: found_employer.id,
        # hired_on: {"$lte" => start_date},
        encrypted_ssn: CensusMember.encrypt_ssn(subscriber_ssn)
      })
      non_terminated_employees = candidate_employees.reject do |ce|
        (!ce.employment_terminated_on.blank?) && ce.employment_terminated_on <= Date.today
      end
    
      @found_employee = non_terminated_employees.sort_by(&:hired_on).last
    end

    def find_plan 
      return @plan unless @plan.nil?
      return nil if hios_id.blank?
      clean_hios = hios_id.strip
      corrected_hios_id = (clean_hios.end_with?("-01") ? clean_hios : clean_hios + "-01")
      @plan = Plan.where({
        active_year: plan_year.to_i,
        hios_id: corrected_hios_id
      }).first
    end

    def find_employer
      return @found_employer unless @found_employer.nil?
      org = Organization.where(:fein => fein).first
      return nil unless org
      @found_employer = org.employer_profile
    end

    PersonSlug = Struct.new(:name_pfx, :first_name, :middle_name, :last_name, :name_sfx, :ssn, :dob, :gender)

    def examine_and_maybe_merge_poc(employer, employee)
      staff_roles = employer.staff_roles
      staff_roles_to_merge = staff_roles.select do |sr|
        (employee.first_name.downcase.strip == sr.first_name.downcase.strip) &&
          (employee.last_name.downcase.strip == sr.last_name.downcase.strip)
      end

      if staff_roles_to_merge.empty?
        return true
      end

      if staff_roles_to_merge.count > 1
        errors.add(:base, "this employee has the same personal data as multiple points of contact")
        return false
      end

      merge_staff = staff_roles_to_merge.first
      existing_people = Person.match_by_id_info(ssn: employee.ssn, dob: employee.dob, last_name: employee.last_name, first_name: employee.first_name)

      if existing_people.count > 1
        errors.add(:base, "matching conflict for this personal data")
        return false
      end

      if existing_people.empty?
        begin
          merge_staff.update_attributes!(:dob => employee.dob, :ssn => employee.ssn, :gender => employee.gender)
        rescue Exception  => e
          errors.add(:base, e.to_s)
        end
        return true
      end

      existing_person = existing_people.first

      if existing_person.has_active_employer_staff_role?
        #only in new model employer staff role already exist
        # Future needs to handle one person with 2  different staff roles
        staff_role_id = existing_person.user.id if existing_person.user
        existing_person.unset(:user_id)
        merge_staff.set(:user_id => staff_role_id) if staff_role_id
        existing_person.destroy!
        merge_staff.save!
        return true
      end

      merge_poc_and_employee_person(merge_staff, existing_person, employer)
      true
    end

    def merge_poc_and_employee_person(poc_person, employee_person, employer)
      return true if poc_person.id == employee_person.id
      staff_role_to_migrate = poc_person.employer_staff_roles.detect do |sr|
        (sr.employer_profile_id == employer.id) && 
          (sr.is_active?)
      end
      poc_person.employer_staff_roles.delete(staff_role_to_migrate)
      poc_person.save!
      employee_person.employer_staff_roles << staff_role_to_migrate
      employee_person.save!
      poc_user = poc_person.user
      emp_user = employee_person.user
      unless poc_user.nil? 
        poc_person.unset(:user_id)
        if emp_user.nil?
          employee_person.set(:user_id => poc_user.id)
        else
          poc_user.destroy!
        end 
      end
    end

    def save
      return false unless valid?
      employer = find_employer      
      employee = find_employee
      benefit_sponsorship = employer.active_benefit_sponsorship

      unless examine_and_maybe_merge_poc(employer, employee)
        return false
      end

      plan = find_plan
      rating_area_id = employer.active_benefit_application.recorded_rating_area_id
      bga = find_benefit_group_assignment

      # add when benefit_group_assignments not added to employees
      if bga.blank?
        plan_years = employer.plan_years.select{|py| py.coverage_period_contains?(start_date) }

        if plan_years.any?{|py| py.conversion_expired? }
          errors.add(:base, "ER migration expired!")
          return false
        end

        if active_plan_year = plan_years.detect{|py| (PlanYear::PUBLISHED + ['expired']).include?(py.aasm_state.to_s)}
          employee.add_benefit_group_assignment(active_plan_year.benefit_groups.first, active_plan_year.start_on)
          employee.reload
          bga = employee.benefit_group_assignments.first
        end
      end

      person_data = PersonSlug.new(nil, employee.first_name, employee.middle_name,
                                   employee.last_name, employee.name_sfx,
                                   employee.ssn,
                                   employee.dob,
                                   employee.gender)
      begin
        role, family = Factories::EnrollmentFactory.construct_employee_role(nil, employee, person_data)

        if role.nil? && family.nil?
          errors.add(:base, "matching conflict for this personal data")
          return false
        end

        unless role.person.save
          role.person.errors.each do |attr, err|
            errors.add("employee_role_" + attr.to_s, err)
          end
          return false
        end

        unless family.save
          family.errors.each do |attr, err|
            errors.add("family_" + attr.to_s, err)
          end
          return false
        end

        cancel_other_enrollments_for_bga(bga)
        house_hold = family.active_household
        coverage_household = house_hold.immediate_family_coverage_household

        benefit_package   = bga.benefit_package
        sponsored_benefit = benefit_package.sponsored_benefit_for('health')
        # for regular conversions we are setting flag to true and mid_year_conversions to false
        set_external_enrollments = @mid_year_conversion ? false : true

        en = house_hold.new_hbx_enrollment_from({
          coverage_household: coverage_household,
          employee_role: role,
          benefit_group: bga.benefit_group,
          benefit_group_assignment: bga,
          coverage_start: start_date,
          enrollment_kind: "open_enrollment",
          external_enrollment: set_external_enrollments
          })

        en.hbx_enrollment_members.each do |mem|
          mem.eligibility_date = start_date
          mem.coverage_start_on = start_date
        end
        en.save!

        if plan.is_a?(BenefitMarkets::Products::Product)
          en.product = plan
        else
          en.plan = plan
        end

        en_attributes = {
          aasm_state: en.effective_on > TimeKeeper.date_of_record ? "coverage_selected" : "coverage_enrolled",
          coverage_kind: 'health'
        }

        unless employer.is_a?(EmployerProfile)
          en_attributes.merge!({
            benefit_sponsorship_id: benefit_sponsorship.id,
            sponsored_benefit_package_id: benefit_package.id,
            sponsored_benefit_id: sponsored_benefit.id,
            rating_area_id: rating_area_id
          })
        end

        en.update_attributes!(en_attributes)
        true
      rescue Exception => e
        errors.add(:base, e.to_s)
        return false
      end
    end

    def cancel_other_enrollments_for_bga(bga)
      enrollments = HbxEnrollment.find_enrollments_by_benefit_group_assignment(bga)
      enrollments.each do |en|
        en.hbx_enrollment_members.each do |hen|
           hen.coverage_end_on = hen.coverage_start_on
        end
        en.terminated_on = en.effective_on
        en.aasm_state = "coverage_canceled"
        en.save!
      end
    end
  end
end
