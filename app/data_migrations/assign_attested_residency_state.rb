require File.join(Rails.root, "lib/mongoid_migration_task")

class AssignAttestedResidency < MongoidMigrationTask
  def families
    Family.by_enrollment_individual_market.all_enrollments.by_enrollment_effective_date_range(TimeKeeper.date_of_record.beginning_of_year, TimeKeeper.date_of_record.end_of_year)
  end

  def assign_attested(family_member, i)
    puts "#{i} assigning status for #{family_member.id} ..." unless Rails.env.test?
    family_member.person.consumer_role.update_attributes(:local_residency_validation => "attested")
  end

  def migrate
    families.each_with_index do |family, i|
      family.family_members.each do |family_member|
        begin
          assign_attested(family_member, i) if family_member.person.consumer_role && family_member.person.consumer_role.local_residency_validation != "outstanding"
        rescue
          $stderr.puts "Issue migrating family_id: #{family.id}, family_member_id: #{family_member.id}" unless Rails.env.test?
        end
      end
    end
  end
end
