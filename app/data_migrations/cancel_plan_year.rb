require File.join(Rails.root, "lib/mongoid_migration_task")

class CancelPlanYear < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])

    if organizations.size != 1
      puts "Found No (or) more than 1 organization with the given fein" unless Rails.env.test?
      return
    end

    plan_year = organizations.first.employer_profile.plan_years.where(aasm_state: ENV['plan_year_state'].to_s).first
    enrollments = all_enrollments(plan_year.benefit_groups)
    if enrollments.present?
      enrollments.each { |enr| enr.cancel_coverage! if enr.may_cancel_coverage? }
      puts "canceled enrollments for this plan year" unless Rails.env.test?
    else
      puts "No enrollments under this plan year" unless Rails.env.test?
    end
    if plan_year.may_cancel?
      plan_year.cancel!
      puts "canceled plan year" unless Rails.env.test?
    elsif plan_year.may_cancel_renewal?
      plan_year.cancel_renewal!
      puts "canceled renewal plan year" unless Rails.env.test?
    end
  end

  def all_enrollments(benefit_groups=[])
    id_list = benefit_groups.collect(&:_id).uniq
    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).to_a
    end
  end
end
