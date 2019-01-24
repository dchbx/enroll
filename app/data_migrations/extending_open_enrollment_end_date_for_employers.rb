require File.join(Rails.root, "lib/mongoid_migration_task")

class ExtendingOpenEnrollmentEndDateForEmployers < MongoidMigrationTask

  def migrate
    feins = ENV['feins'].to_s.split(",").map(&:strip) if ENV['feins'].present?

    plan_year_start_on = Date.strptime((ENV['py_start_on']).to_s, "%m/%d/%Y")
    new_open_enrollment_end_on_date = Date.strptime((ENV['new_oe_end_date']).to_s, "%m/%d/%Y")
    
    if feins.present?
      organizations = Organization.where(:"fein".in => feins)
    else
      organizations = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => plan_year_start_on, :aasm_state.in => PlanYear::RENEWING}})
    end

    count = 0
    organizations.each do |org|
      org.employer_profile.plan_years.where(:start_on => plan_year_start_on, :aasm_state.in => PlanYear::RENEWING).first.update_attribute(:open_enrollment_end_on, new_open_enrollment_end_on_date)
      puts "Changing Open Enrollment End On date for #{org.legal_name}" unless Rails.env.test?
      count = count+1
    end
    puts "Total effected ER's count is #{count}" unless Rails.env.test?
  end
end
