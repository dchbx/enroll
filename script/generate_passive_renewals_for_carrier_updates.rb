orgs = Organization.where({:"employer_profile.plan_years" => { 
  :$elemMatch => { 
    :start_on => TimeKeeper.date_of_record.next_month.beginning_of_month, 
    :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE }
    }})

count = 0
invlid_renewals = []

orgs.each do |org|
  puts "processing #{org.legal_name}"

  renewal_plan_year = org.employer_profile.renewing_plan_year
  active_plan_year = org.employer_profile.active_plan_year

  if active_plan_year.blank?
    puts "Active Plan Year missing for #{org.legal_name} #{org.fein}"
    next
  end

  id_list = renewal_plan_year.benefit_groups.collect(&:_id).uniq
  active_id_list = active_plan_year.benefit_groups.collect(&:_id).uniq

  Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list).each do |family|

    enrollments = family.active_household.hbx_enrollments.where(:"benefit_group_id".in => id_list).by_coverage_kind("health")

    if enrollments.where(:aasm_state.in =>  ["renewing_waived", "auto_renewing"]).size > 1
      puts "Found more than 1 passive renewal for #{family.primary_applicant.full_name}"
      next
    end

    if enrollments.where(:aasm_state.in => ["coverage_selected", "coverage_terminated", "inactive"]).any?
      enrollments.renewing.each do |enrollment|
        puts "Cancelling passive renewal for #{family.primary_applicant.full_name}"
        enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
      end
    else
      current_enrollments = family.active_household.hbx_enrollments.where(:"benefit_group_id".in => active_id_list).by_coverage_kind("health").enrolled

      if current_enrollments.present?
        current_coverage = current_enrollments.order(created_at: :desc).first
        renewal_enrollment = enrollments.where(:aasm_state.in =>  ["renewing_waived", "auto_renewing"]).first
        ce = current_coverage.benefit_group_assignment.census_employee

        if renewal_enrollment.blank? || renewal_enrollment.renewing_waived? || (current_coverage.updated_at.to_i > renewal_enrollment.created_at.to_i)
          puts "Generating passive renewal for #{family.primary_applicant.full_name}"
          renewal_enrollment.cancel_coverage! if renewal_enrollment.present?

          factory = Factories::FamilyEnrollmentRenewalFactory.new
          factory.family = family
          factory.census_employee = ce
          factory.employer = org.employer_profile
          factory.renewing_plan_year = renewal_plan_year
          factory.renew
        end
      else
        renewal_enrollments = enrollments.where(:aasm_state.in =>  ["renewing_waived", "auto_renewing"])
        if renewal_enrollments.size == 1 && renewal_enrollments.first.renewing_waived?
          next
        elsif renewal_enrollments.size > 0
          puts "Renewal generated without prev year enrollment for #{family.primary_applicant.full_name}"
        else renewal_enrollments.size == 0
        end
      end
    end
  end
end
