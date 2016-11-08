namespace :migrations do

  desc "Cancel renewal for employer"
  task :cancel_employer_renewal, [:fein] => [:environment] do |task, args|

    employer_profile = EmployerProfile.find_by_fein(args[:fein])

    if employer_profile.blank?
      raise 'unable to find employer'
    end

    puts "Processing #{employer_profile.legal_name}"
    organizations = Organization.where(fein: args[:fein])
    organizations.each do |organization|
      renewing_plan_year = organization.employer_profile.plan_years.renewing.first
      if renewing_plan_year.present?
        enrollments = enrollments_for_plan_year(renewing_plan_year)
        enrollments.each do |enrollment|
          enrollment.cancel_coverage!
        end

        puts "found renewing plan year for #{organization.legal_name}---#{renewing_plan_year.start_on}"
        renewing_plan_year.cancel_renewal! if renewing_plan_year.may_cancel_renewal?
      end
      organization.employer_profile.revert_application! if organization.employer_profile.may_revert_application?
    end
  end

  desc "Cancel incorrect renewal for employer"
  task :cancel_employer_incorrect_renewal, [:fein, :plan_year_start_on] => [:environment] do |task, args|

    employer_profile = EmployerProfile.find_by_fein(args[:fein])

    if employer_profile.blank?
      puts "employer profile not found!"
      exit
    end

    plan_year_start_on = Date.strptime(args[:plan_year_start_on], "%m/%d/%Y")

    if plan_year = employer_profile.plan_years.where(:start_on => plan_year_start_on).published.first
      enrollments = enrollments_for_plan_year(plan_year)
      if enrollments.any?
        puts "Canceling employees coverage for employer #{employer_profile.legal_name}"
      end

      enrollments.each do |hbx_enrollment|
        if hbx_enrollment.may_cancel_coverage?
          hbx_enrollment.cancel_coverage!
          # Just make sure cancel propograted
        end
      end

      puts "canceling plan year for employer #{employer_profile.legal_name}"
      plan_year.cancel!
      puts "cancellation successful!"
    else
      puts "renewing plan year not found!!"
    end
  end
end

def enrollments_for_plan_year(plan_year)
  id_list = plan_year.benefit_groups.map(&:id)
  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  enrollments = families.inject([]) do |enrollments, family|
    enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
  end
end
