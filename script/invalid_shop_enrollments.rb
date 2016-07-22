def enrollments_by_benefit_groups(benefit_groups = [])
  id_list = benefit_groups.collect(&:_id).uniq

  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  families.inject([]) do |enrollments, family|
    enrollments += family.active_household.hbx_enrollments.by_coverage_kind("health").where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector, HbxEnrollment::terminated.selector]).to_a
  end
end

def plan_year_invalid_enrollments(plan_year)
  enrollments = enrollments_by_benefit_groups(plan_year.benefit_groups).group_by{|e| e.benefit_group_id}

  enrollments.inject([]) do |invalid, (benefit_group_id, enrollments)|
    benefit_group = plan_year.benefit_groups.detect{|bg| bg.id == benefit_group_id}
    invalid += enrollments.select{|e| !benefit_group.elected_plan_ids.include?(e.plan_id)}.compact
  end
end

def find_enrollments_with_invalid_plans
  CSV.open("enrollments_with_plans_not_offered_by_emploeyrs.csv", "w") do |csv|

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
      'Enrollment Created At'
    ]

    Organization.exists(:employer_profile => true).each do |org|

      puts "---processing #{org.legal_name}"

      invalid_enrollments = []

      if plan_year = org.employer_profile.active_plan_year
        invalid_enrollments += plan_year_invalid_enrollments(plan_year)
      end

      if plan_year = org.employer_profile.renewing_published_plan_year
        invalid_enrollments += plan_year_invalid_enrollments(plan_year)
      end

      invalid_enrollments.each do |enrollment|
        # next unless enrollment.auto_renewing?
        person = enrollment.family.primary_applicant.person
        begin
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
          enrollment.created_at.present? ? enrollment.created_at.strftime("%m/%d/%Y") : nil
        ]

        # enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
      rescue Exception => e
        puts "#{person.full_name}---#{e.to_s}"
      end
      end
    end
  end
end


find_enrollments_with_invalid_plans


