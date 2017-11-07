require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeAASMStateOfUnVerifiedConsumers < MongoidMigrationTask
  def migrate
    begin
      unverified_consumers = Person.where(:"consumer_role.aasm_state".in => ["verification_period_ended?", "verification_outstanding"])
      unverified_consumers.each do |person|
        families = [person.primary_family].compact
        if families.empty?
          families = person.families
        end
        families.each do |family|
          coverage_selected_enrollments = family.enrollments.where(:aasm_state => "coverage_selected")
          coverage_selected_enrollments.each do |enrollment|
            puts "Moving Enrollment to Contigent " unless Rails.env.test?
            enrollment.move_to_contingent!
          end
        end
      end
    rescue => e
      puts "#{e}"
    end
  end
end