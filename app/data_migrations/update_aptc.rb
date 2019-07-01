require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateAptc < MongoidMigrationTask
  def migrate
    begin
      enrollments = HbxEnrollment.gt("elected_amount.cents"=> 0)
      enrollments.each do |enrollment|
        if enrollment.elected_amount.to_f > 0 and enrollment.applied_aptc_amount.to_f == 0
          enrollment.update_attributes!(applied_aptc_amount: enrollment.elected_amount.to_f) 
          count += 1
        end
      end
      puts "updated #{count} hbx_enrollments for applied_aptc_amount" unless Rails.env.test?
    rescue
      puts "Unable to find enrollments with elected_amount is greater than zero" unless Rails.env.test?
    end
  end
end
