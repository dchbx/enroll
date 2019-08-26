# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class AddSbcRoleToPerson < MongoidMigrationTask
  def migrate
    hbx_ids = ENV['hbx_id'] || ""
    hbx_ids.split(",").each do |hbx_id|
      person = Person.where(hbx_id: hbx_id)[0]
      raise "Invalid Hbx Id" if person.blank?

      person.create_sbc_role if person.sbc_role.blank?
      puts "Successfully created sbc role for #{person.full_name}" unless Rails.env.test?
    end

    # assign sbc_role to super admins
    super_admin_id = Permission.super_admin&.id.to_s
    persons = ::Person.where(:"hbx_staff_role.permission_id" => BSON::ObjectId.from_string(super_admin_id))
    persons.each do |person|
      person.create_sbc_role if person.sbc_role.blank?
      puts "Successfully created sbc role for #{person.full_name}" unless Rails.env.test?
    end
  end
end
