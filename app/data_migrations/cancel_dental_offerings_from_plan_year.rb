
require File.join(Rails.root, "lib/mongoid_migration_task")

class CancelDentalOfferingsFromPlanYear < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    state = ENV['aasm_state']
    bg_id = ENV['benefit_group_id']
    if organizations.size != 1
      puts 'issues with given fein'
      return
    end
    benefit_group_id_list = organizations.first.employer_profile.plan_years.where(aasm_state: state).first.benefit_groups.map(&:id).uniq
    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => benefit_group_id_list)
      families.each do |family|
      family.active_household.hbx_enrollments.where(coverage_kind: "dental").each do |enrollment|
        enrollment.update_attributes(aasm_state: "coverage_canceled")
        puts "canceling the enrollment" unless Rails.env.test?
      end
    end
    organizations.first.employer_profile.plan_years.where(aasm_state: state).first.benefit_groups.where(_id: bg_id).first.unset(:dental_reference_plan_id)
    puts "canceling the dental offerings" unless Rails.env.test?
  end
end
