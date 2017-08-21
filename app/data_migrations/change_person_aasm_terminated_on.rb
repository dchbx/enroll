require File.join(Rails.root, "lib/mongoid_migration_task")
require 'date'
class ChangePersonAasmTerminatedOn< MongoidMigrationTask
  def migrate
    hbx_id=ENV['hbx_id']
    enrollment_hbx_id=ENV['enrollment_hbx_id']
    terminated_on = Date.strptime(ENV['terminated_on'],'%m/%d/%Y')
    # aasm_state1 = ENV['aasm_state']
    person=Person.where(hbx_id:ENV['hbx_id']).first
    hbxenrollment=person.primary_family.active_household.hbx_enrollments.where(hbx_id: enrollment_hbx_id)

    if person.nil?
      puts "No person was found by the given hbx_id" unless Rails.env.test?
    else
      hbxenrollment.first.update_attributes(aasm_state: ENV['aasm_state'])
      hbxenrollment.first.update_attributes(terminated_on: terminated_on)
      puts "Changed aasm_state to #{aasm_state} and terminated to #{terminated_on}" unless Rails.env.test?
      puts "Changed date of terminated to #{terminated_on}" unless Rails.env.test?
    end
  end
end
