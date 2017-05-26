module Importers
  class ConversionEmployeePolicyDelete < ConversionEmployeePolicyCommon

    validate :validate_fein
    validate :employee_exists
    validates_length_of :fein, is: 9
    validates_length_of :subscriber_ssn, is: 9

    def employee_exists
      found_employer = find_employer
      return true if found_employer.nil?
      return true if subscriber_ssn.blank?
      found_employee = find_employee
      if found_employee.nil?
        errors.add(:subscriber_ssn, "unable to find employee")
      end
    end

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      end
    end

    def find_employer
      org = Organization.where(:fein => fein).first
      return nil unless org
      org.employer_profile
    end

    def save
      return false unless valid?
      found_employee = find_employee
      employer = found_employee.employer_profile
      active_plan_year = employer.active_plan_year

      # employee_role = found_employee.employee_role
      # if employee_role.blank?
      #   errors.add(:subscriber_ssn, "employee role missing")
      #   return false 
      # end

      # person = employee_role.person
      # hbx_enrollments = person.primary_family.enrollments

      hbx_enrollments = []
      found_employee.benefit_group_assignments.each do |assignment|
        hbx_enrollments += HbxEnrollment.find_enrollments_by_benefit_group_assignment(assignment)
      end
      hbx_enrollments.uniq!

      employment_terminated_on = TimeKeeper.date_of_record.end_of_month

      if active_plan_year.present?
        bg_ids = active_plan_year.benefit_groups.map(&:id)
        if (active_plan_year.start_on == TimeKeeper.date_of_record.beginning_of_month)
          employment_terminated_on = TimeKeeper.date_of_record.beginning_of_month
          hbx_enrollments.each do |hbx_enrollment|
            if bg_ids.include?(hbx_enrollment.benefit_group_id) &&  hbx_enrollment.may_cancel_coverage?
              hbx_enrollment.cancel_coverage!
            end
          end
        else
          hbx_enrollments.each do |hbx_enrollment|
            if bg_ids.include?(hbx_enrollment.benefit_group_id) &&  hbx_enrollment.may_terminate_coverage?
              hbx_enrollment.update_attributes(:terminated_on => employment_terminated_on)
              hbx_enrollment.terminate_coverage!
            end
          end
        end
      end

      renewing_plan_year = employer.renewing_plan_year
      if renewing_plan_year.present?
        bg_ids = renewing_plan_year.benefit_groups.map(&:id)
        hbx_enrollments.each do |hbx_enrollment|
          if bg_ids.include?(hbx_enrollment.benefit_group_id) &&  hbx_enrollment.may_cancel_coverage?
            hbx_enrollment.cancel_coverage!
          end
        end
      end

      found_employee.terminate_employment(employment_terminated_on)

      unless found_employee.employment_terminated?
        propagate_errors(found_employee)
        return false
      end

      true
    end

    def propagate_errors(census_employee)
      census_employee.errors.each do |attr, err|
        errors.add("census_employee_" + attr.to_s, err)
      end
      census_employee.census_dependents.each_with_index do |c_dep, idx|
        c_dep.errors.each do |attr, err|
          errors.add("dependent_#{idx}_" + attr.to_s, err)
        end
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

  end
end
