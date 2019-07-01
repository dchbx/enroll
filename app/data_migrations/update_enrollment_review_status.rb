require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateReviewStatus < MongoidMigrationTask
  def get_families
    Family.by_enrollment_individual_market.all_with_hbx_enrollments
  end

  def migrate
    families_to_check = get_families
    families_to_check.each do |family|
      enrollments = family.active_household.hbx_enrollments
      enrollments.each do |enrollment|
        begin
          enrollment.update_attributes!(:review_status => "incomplete") unless enrollment.review_status
        rescue
          $stderr.puts "Issue migrating enrollment: enrollment #{enrollment.id}, family #{family.id}"
        end
      end
    end
  end
end