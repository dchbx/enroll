require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateSpecialEnrollmentPeriodEffectiveDate < MongoidMigrationTask
  def migrate
    begin
      sep_id = ENV['special_enrollment_period_id']
      effective_date = ENV['effective_date'] if ENV['effective_date'].present?
      record = SpecialEnrollmentPeriod.find(sep_id)
      if effective_date.present?
        record.update_attributes(next_poss_effective_date: effective_date)
      end
    rescue => e
      puts "#{e.message}"
    end
  end
end
