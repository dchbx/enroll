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

  desc "Cancel conversion employer renewals"
  task :conversion_employer_renewal_cancellations => :environment do 
    count = 0
    prev_canceled = 0

    employer_feins = [
        "043774897","541206273","522053522","200247609","521321945","522402507",
        "522111704","204314853","521766976","260771506","264288621","521613732",
        "800501539","521844112","521932886","530229573","521072698","204229835",
        "521847137","383796793","521990963","770601491","200316239","541668887",
        "431973129","522008056","264391330","030458695","452698846","521490485",
        "264667460","550894892","521095089","208814321","593400922","521899983"
    ]
    
    employer_feins.each do |fein|
      employer_profile = EmployerProfile.find_by_fein(fein)

      if employer_profile.blank?
        puts "employer profile not found!"
        return
      end

      plan_year = employer_profile.renewing_plan_year
      if plan_year.blank?
        plan_year = employer_profile.plan_years.published.detect{|py| py.start_on.year == 2016}
      end

      if plan_year.blank?
        puts "#{employer_profile.legal_name} --no renewal plan year found!!"
        prev_canceled += 1
        next
      end

      plan_year.hbx_enrollments.each do |enrollment|
        enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
      end

      employer_profile.census_employees.each do |census_employee|
        assignments = census_employee.benefit_group_assignments.where(:benefit_group_id.in => plan_year.benefit_groups.map(&:id))
        assignments.each do |assignment|
          assignment.delink_coverage! if assignment.may_delink_coverage?
        end
      end

      plan_year.cancel! if plan_year.may_cancel?
      plan_year.cancel_renewal! if plan_year.may_cancel_renewal?
      employer_profile.revert_application! if employer_profile.may_revert_application?

      count += 1
    end

    puts "Canceled #{count} employers"
    puts "#{prev_canceled} Previously Canceled employers"
  end
end

def enrollments_for_plan_year(plan_year)
  id_list = plan_year.benefit_groups.map(&:id)
  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  enrollments = families.inject([]) do |enrollments, family|
    enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
  end
end
