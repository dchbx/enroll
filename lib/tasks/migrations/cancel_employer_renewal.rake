# This rake task used to cancel renewing plan year and renewing enrollments.
# ex: RAILS_ENV=production bundle exec rake migrations:cancel_employer_renewal['521111111 522221111 5211333111']

namespace :migrations do

  desc "Cancel renewal for employer"
  task :cancel_employer_renewal, [:fein] => [:environment] do |task, args|

    feins = args[:fein].split(' ').uniq

    feins.each do |fein|

      employer_profile = EmployerProfile.find_by_fein(fein)
      next puts "unable to find employer_profile with fein: #{fein}" if employer_profile.blank?

      # checking renewing_application_ineligible assm state plan year here, as aasm state not listed in renewing.
      renewing_plan_year = employer_profile.plan_years.renewing.first || employer_profile.plan_years.where(aasm_state:'renewing_application_ineligible').first

      if renewing_plan_year.present?
        puts "found renewing plan year for #{employer_profile.legal_name}---#{renewing_plan_year.start_on}" unless Rails.env.test?

        enrollments_for_plan_year(renewing_plan_year).each do |enrollment|
          if enrollment.may_cancel_coverage?
            enrollment.cancel_coverage!
            puts "canceling employees coverage for employer enrollment hbx_id:#{enrollment.hbx_id}" unless Rails.env.test?
          end
        end

        employer_profile.census_employees.each do |census_employee|
          assignments = census_employee.benefit_group_assignments.where(:benefit_group_id.in => renewing_plan_year.benefit_groups.map(&:id))
          assignments.each do |assignment|
            if assignment.may_delink_coverage?
              assignment.delink_coverage!
              assignment.update_attribute(:is_active, false)
            end
          end
        end

        if renewing_plan_year.may_cancel_renewal?
          puts "canceling plan year for employer #{employer_profile.legal_name}" unless Rails.env.test?
          renewing_plan_year.cancel_renewal!
        end

        employer_profile.revert_application! if employer_profile.may_revert_application?
      else
        puts "renewing plan year not found for employer #{employer_profile.legal_name}" unless Rails.env.test?
      end
    end
  end

# This rake task used to cancel published plan year & active enrollments.
# ex: RAILS_ENV=production bundle exec rake migrations:cancel_employer_incorrect_renewal['473089323 472289323 4730893333' ]

  desc "Cancel incorrect renewal for employer"
  task :cancel_employer_incorrect_renewal, [:fein] => [:environment] do |task, args|

    feins = args[:fein].split(' ').uniq

    feins.each do |fein|

      employer_profile = EmployerProfile.find_by_fein(fein)
      next puts "unable to find employer_profile with fein: #{fein}" if employer_profile.blank?

      plan_year = employer_profile.plan_years.published.first

      if plan_year.present?
        puts "found  plan year for #{employer_profile.legal_name}---#{plan_year.start_on}" unless Rails.env.test?

        enrollments_for_plan_year(plan_year).each do |hbx_enrollment|
          if hbx_enrollment.may_cancel_coverage?
            hbx_enrollment.cancel_coverage!
            puts "canceling employees coverage for employer enrollment hbx_id:#{hbx_enrollment.hbx_id}" unless Rails.env.test?
          end
        end

        employer_profile.census_employees.each do |census_employee|
          assignments = census_employee.benefit_group_assignments.where(:benefit_group_id.in => plan_year.benefit_groups.map(&:id))
          assignments.each do |assignment|
            if assignment.may_delink_coverage?
              assignment.delink_coverage!
              assignment.update_attribute(:is_active, false)
            end
          end
        end

        if plan_year.may_cancel?
          plan_year.cancel!
          puts "canceling plan year for employer #{employer_profile.legal_name}" unless Rails.env.test?
        end

        employer_profile.revert_application! if employer_profile.may_revert_application?
      else
        puts "renewing plan year not found #{employer_profile.legal_name}" unless Rails.env.test?
      end
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
  HbxEnrollment.where(:"benefit_group_id".in => id_list).any_of([HbxEnrollment::enrolled.selector, HbxEnrollment::renewing.selector]).to_a
end
