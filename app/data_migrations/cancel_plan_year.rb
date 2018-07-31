require File.join(Rails.root, "lib/mongoid_migration_task")

class CancelPlanYear < MongoidMigrationTask
  def migrate
    feins=ENV['feins'].split(' ').uniq
    feins.each do |fein|
      organizations = Organization.where(fein: fein)
      next puts "unable to find employer_profile with fein: #{fein}" if organizations.blank?

      if organizations.size > 1
        raise 'more than 1 employer found with given fein'
      end
      plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
      plan_year = organizations.first.employer_profile.plan_years.where(:start_on => plan_year_start_on, :aasm_state => ENV['plan_year_state'].to_s).first
      next puts "Present fein: #{fein} is found but it has different plan year assm state" if plan_year.nil?
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
  end

  def all_enrollments(benefit_groups=[])
    id_list = benefit_groups.collect(&:_id).uniq
    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).to_a
    end
  end
end
