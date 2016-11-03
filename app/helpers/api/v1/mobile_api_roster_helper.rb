module Api::V1::MobileApiRosterHelper

 def employees_by(employer_profile, by_employee_name = nil, by_status = 'active')
    census_employees = case by_status
                   when 'terminated'
                     employer_profile.census_employees.terminated
                   when 'all'
                     employer_profile.census_employees
                   else
                     employer_profile.census_employees.active
                   end.sorted
    by_employee_name ? census_employees.employee_name(by_employee_name) : census_employees
  end

  def status_label_for(enrollment_status)
  	{
      'Waived' => HbxEnrollment::WAIVED_STATUSES,
      'Enrolled' => HbxEnrollment::ENROLLED_STATUSES,
      'Terminated' => HbxEnrollment::TERMINATED_STATUSES,
      'Renewing' => HbxEnrollment::RENEWAL_STATUSES
    }.inject(nil) do |result, (label, enrollment_statuses)|
         enrollment_statuses.include?(enrollment_status.to_s) ? label : result
    end
  end

  def relationship_with(dependent)
  	dependent.try(:relationship) || dependent.try(:employee_relationship)
  end
  
  def dependents_of(census_employee)
    all_family_dependents = census_employee.try(:employee_role).try(:person).try(:primary_family).try(:active_family_members) || []
    family_dependents = all_family_dependents.reject { |d| relationship_with(d) == "self" }
    census_dependents = census_employee.census_dependents || []
  	(family_dependents + census_dependents).uniq { |p| p.ssn }
  end


  def render_individual(individual)
  	ssn = individual.try(:ssn)	
  	ssn_masked = "***-**-#{ ssn.chars.last(4).join }" if ssn

  	{
  	  first_name:        individual.try(:first_name),
      middle_name:       individual.try(:middle_name),
      last_name:         individual.try(:last_name),
      name_suffix:       individual.try(:name_sfx),
      date_of_birth:     individual.try(:dob),
      ssn_masked:        ssn_masked, 
      gender:            individual.try(:gender)
  	}
  end

  ROSTER_ENROLLMENT_PLAN_FIELDS_TO_RENDER = [:plan_type, :deductible, :family_deductible, :provider_directory_url, :rx_formulary_url]  
  def render_roster_employee(census_employee, has_renewal)
    assignments = { active: census_employee.active_benefit_group_assignment }
    assignments[:renewal] = census_employee.renewal_benefit_group_assignment if has_renewal
    enrollments = {}
    assignments.keys.each do |period_type|
      assignment = assignments[period_type]
      enrollments[period_type] = {}
      %w{health dental}.each do |coverage_kind|
          enrollment = assignment.hbx_enrollments.detect { |e| e.coverage_kind == coverage_kind } if assignment
          rendered_enrollment = if enrollment then
            {
              status: status_label_for(enrollment.aasm_state),
              employer_contribution: enrollment.total_employer_contribution,
              employee_cost: enrollment.total_employee_cost,
              total_premium: enrollment.total_premium,
              plan_name: enrollment.plan.try(:name),
              plan_type: enrollment.plan.try(:plan_type),
              metal_level:  enrollment.plan.try(coverage_kind == :health ? :metal_level : :dental_level),
			        benefit_group_name: enrollment.benefit_group.title
            } 
          else 
            {
              status: 'Not Enrolled'
            }
          end
          if enrollment && enrollment.plan 
            ROSTER_ENROLLMENT_PLAN_FIELDS_TO_RENDER.each do |field|
              value = enrollment.plan.try(field)
              rendered_enrollment[field] = value if value
            end
          end
          if rendered_enrollment[:status] == "Terminated"
            rendered_enrollment[:terminated_on] = enrollment.terminated_on  
            rendered_enrollment[:terminate_reason] = enrollment.terminate_reason
          end
          enrollments[period_type][coverage_kind] = rendered_enrollment
      end
    end

    result = render_individual(census_employee)
    result[:id]   				            = census_employee.id
    result[:hired_on] 			          = census_employee.hired_on
    result[:is_business_owner]        = census_employee.is_business_owner
    result[:enrollments] 		          = enrollments
    result[:dependents]			          = dependents_of(census_employee).map do |d| 
    	render_individual(d).merge(relationship: relationship_with(d)) 
    end

    result

  end

  def render_roster_employees(employees, has_renewal)
    employees.compact.map do |ee| 
      render_roster_employee(ee, has_renewal) 
    end
  end

end