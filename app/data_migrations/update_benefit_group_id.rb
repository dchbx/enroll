require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateBenefitGroupId < MongoidMigrationTask
  def migrate
    begin
      enrollment_hbx_id = ENV['enrollment_hbx_id']
      benefit_group_id = ENV['benefit_group_id'].to_s
      hbx_enrollment = HbxEnrollment.by_hbx_id(enrollment_hbx_id)
      if hbx_enrollment.first.nil?
        puts "No Enrollment was found with given hbx_id" unless Rails.env.test?
      else
        if hbx_enrollment.first.benefit_group.present?
          puts " This HbxEnrollment has a benefit group which is not nil" unless Rails.env.test?
          else
            hbx_enrollment.first.benefit_group_id = benefit_group_id
              if hbx_enrollment.first.valid?
                 hbx_enrollment.first.save!
                 hbx_enrollment.first.hbx_id
              end
        end  
      end
    rescue => e
      puts "#{e}"
    end
  end
end