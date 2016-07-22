namespace :migrations do

  desc "Cancel renewal for employer"
  task :cancel_employer_renewal => :environment do

    feins = ["520743373","530026395","550825492","453987501","530164970","237256856",
     "611595539","591640708","521442741","521766561","522167254","521826441",
     "530176859","521991811","522153746","521967581","147381250","520968193",
     "521143054","521943790","520954741","462199955","205862174","521343924",
     "521465311","521816954","020614142","521132764","521246872","307607552",
     "522357359","520978073","356007147","522315929","521989454","942437024",
     "133535334","462612890","541873351","521145355","530071995","521449994"]

    feins.each do |fein|

      employer_profile = EmployerProfile.find_by_fein(fein)

      if employer_profile.blank?
        raise 'unable to find employer'
      end
    
      # employer_profile.census_employees.each do |census_employee|    
      #   census_employee.aasm_state = "eligible" if census_employee.aasm_state = "employee_role_linked"    
      #   census_employee.save
      #   puts "De-linking #{census_employee}"    
      # end

      puts "Processing #{employer_profile.legal_name}"
  
      renewing_plan_year = employer_profile.plan_years.renewing.first
      if renewing_plan_year.present?
        enrollments = enrollments_for_plan_year(renewing_plan_year)
        enrollments.each do |enrollment|
          enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
        end

        renewing_plan_year.cancel_renewal! if renewing_plan_year.may_cancel_renewal?
      end

      employer_profile.revert_application! if employer_profile.may_revert_application?
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
    enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector, HbxEnrollment::waived.selector]).to_a
  end
end
