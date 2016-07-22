def plan_year_invalid_enrollments(plan_year)
  id_list = plan_year.benefit_groups.collect(&:_id).uniq

  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  families.inject([]) do |enrollments, family|
    coverages = family.active_household.hbx_enrollments.by_coverage_kind("health").where(:benefit_group_id.in => id_list)
    valid_coverages = coverages.any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
    valid_coverages.reject!{|c| c.benefit_group_assignment.blank?}
    enrollments += valid_coverages.select{|coverage| coverage.benefit_group_assignment.census_employee.employment_terminated?}.compact
  end
end

def find_enrollments_with_invalid_plans
  CSV.open("terminated_ee_passive_renewals.csv", "w") do |csv|

    csv << [
      'Primary First Name',
      'Primary Last Nmae',
      'Employer Name',
      'Employer FEIN',
      'Conversion Employer',
      'Plan Year Begin',
      'Coverage Start Date', 
      'Plan ID', 
      'Plan Name',
      'Plan Status',
      'Employment Terminated On'
    ]


    Organization.exists(:employer_profile => true).where(
      :"employer_profile.plan_years" => {:$elemMatch => {
        :start_on => Date.new(2015,8,1),
        :aasm_state.in => PlanYear::PUBLISHED
      }}).each do |org|

      puts "---processing #{org.legal_name}"
      if plan_year = org.employer_profile.renewing_published_plan_year

        plan_year_invalid_enrollments(plan_year).each do |enrollment|
          person = enrollment.family.primary_applicant.person
          begin
            terminated_on = enrollment.benefit_group_assignment.census_employee.employment_terminated_on

            csv << [
              person.first_name,
              person.last_name,
              org.legal_name,
              org.fein,
              org.employer_profile.profile_source == 'conversion',
              enrollment.benefit_group.start_on.strftime("%m/%d/%Y"),
              enrollment.effective_on.strftime("%m/%d/%Y"),
              enrollment.plan.try(:hios_id),
              enrollment.plan.try(:name),
              enrollment.aasm_state.humanize.titleize,
              terminated_on.strftime("%m/%d/%Y")
            ]

            if terminated_on > enrollment.benefit_group.start_on
              enrollment.update_attributes(:terminated_on => terminated_on.end_of_month)
              enrollment.terminate_coverage!
              puts "----coverage terminated"
            else
              enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
            end
          rescue Exception => e
            puts "#{person.full_name}---#{e.to_s}"
          end
        end
      end
    end
  end
end

find_enrollments_with_invalid_plans