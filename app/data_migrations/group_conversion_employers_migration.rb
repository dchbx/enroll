
require File.join(Rails.root, "lib/mongoid_migration_task")

class GroupConversionEmployersMigration < MongoidMigrationTask
  def migrate
    fein = ["520818450", "530160510", "262903254", "942233274", "264195952", "900874591", "311799296", "522351337", "731681983", "203142831", "272664900", "520907700", "530068130", "521516688", "471925250"]
    fein.each do |fein|
      organization = Organization.where(fein: fein)
      if organization.size != 1
        puts "Issues with organization of fein #{fein}" unless Rails.env.test?
        next
      end
      organization.first.employer_profile.plan_years.each do |plan_year|
        if plan_year.start_on.year == 2015
          plan_year.migration_expire! if plan_year.may_migration_expire?
        end
      end
      plan_years = organization.first.employer_profile.plan_years.published + organization.first.employer_profile.plan_years.renewing_published_state + organization.first.employer_profile.plan_years.where(aasm_state: "draft") + organization.first.employer_profile.plan_years.where(aasm_state: "renewing_publish_pending")
      plan_years.each do |plan_year|
        if plan_year.start_on.year == 2016
          plan_year.update_attribute(:aasm_state, "canceled")
          id_list = plan_year.benefit_groups.map(&:id)
          families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
          enrollments = families.inject([]) do |enrollments, family|
            enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).any_of([HbxEnrollment::enrolled.selector]).to_a
          end
          enrollments.each do |enrollment|
            enrollment.update_attribute(:aasm_state, "coverage_canceled") if enrollment.effective_on.strftime("%m/%d/%Y") == "10/01/2016" 
          end
        end
      end
      organization.first.employer_profile.revert_application! if organization.first.employer_profile.may_revert_application?
      puts "Reverting the application for #{organization.first.legal_name}" unless Rails.env.test?
    end
  end
end
