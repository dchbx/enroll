person_missing = 0
policy_missing = 0

CSV.foreach("11_1_Reverse_Migration_RESULTS_redmine8905_20160928.csv", :headers => true) do |row|
  hbx_id = row["HBX ID"].strip

  if person = Person.by_hbx_id(hbx_id).first
    renewal_enrollment = person.primary_family.active_household.hbx_enrollments.where(:aasm_state.in => (HbxEnrollment::RENEWAL_STATUSES + ['renewing_waived']) ).first
    if renewal_enrollment.present?

      employer = EmployerProfile.find_by_fein(row["Employer FEIN"].strip)
      eg_id = row["Enrollment Group ID"].strip
      if policy = HbxEnrollment.by_hbx_id(eg_id).first
        
        # bg_ids = employer.active_plan_year.benefit_groups.map(&:id)
        # enrollments = person.primary_family.active_household.hbx_enrollments.enrolled.where(:benefit_group_id.in => bg_ids)

        if renewal_enrollment.renewing_waived?
          renewal_enrollment.delete
        else
          renewal_enrollment.cancel_coverage!
        end

        if employer.plan_years.renewing_published_state.present? && CensusEmployee::EMPLOYMENT_ACTIVE_STATES.include?(policy.benefit_group_assignment.census_employee.aasm_state)
          factory = Factories::FamilyEnrollmentRenewalFactory.new
          factory.family = person.primary_family
          factory.census_employee = policy.benefit_group_assignment.census_employee
          factory.employer = employer
          factory.renewing_plan_year = employer.renewing_plan_year
          factory.renew
        else
          puts "ignoring....#{employer.legal_name}"
        end
      else
        policy_missing += 1
      end
    end
  else
    person_missing += 1
  end
end


puts person_missing.inspect
puts policy_missing.inspect