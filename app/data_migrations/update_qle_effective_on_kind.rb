require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateQleEffectiveOnKind < MongoidMigrationTask
  def migrate
    begin
      qle = QualifyingLifeEventKind.where(title:ENV["title"]).first
      qle.update(effective_on_kinds:["date_of_event"])
    end
  end
end