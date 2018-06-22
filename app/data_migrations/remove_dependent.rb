require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDependent < MongoidMigrationTask
  def migrate
    begin
      id = ENV["family_member_id"].to_s
      family_member = FamilyMember.find(id)
      if family_member.nil?
        puts "No family member found" unless Rails.env.test?
      else
        active_household = family_member.family.active_household
        if (active_household.coverage_households.map(&:coverage_household_members).flatten.map(&:family_member_id).map(&:to_s) & [id]).present? || (active_household.hbx_enrollments.my_enrolled_plans.where(:"aasm_state".ne => "coverage_canceled").map(&:hbx_enrollment_members).flatten.uniq.map(&:applicant_id).map(&:to_s) & [id]).present?
          puts "you cannot destroy this family member. This member may have Coverage Household Member records or Enrollments" unless Rails.env.test?
          return
        else
          family_member.destroy!
          puts "remove duplicate dependent with family member id: #{family_member.id}" unless Rails.env.test?
        end
      end
    rescue Exception => e
      puts e.message
    end
  end
end


