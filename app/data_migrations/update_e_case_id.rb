require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateECaseId < MongoidMigrationTask
  def migrate
    family = Person.where(hbx_id: ENV['hbx_id']).first.families.first
    if family.e_case_id.present?
      e_case_id = family.e_case_id.split('#').first + "##{ENV['e_case_id']}"
      family.update_attributes({e_case_id: e_case_id})
    end
  end
end