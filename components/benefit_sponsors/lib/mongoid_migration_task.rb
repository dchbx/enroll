require 'rake'

class MongoidMigrationTask < Rake::Task
  def initialize(task_name, app)
    super(task_name, app)
    @actions << Proc.new { self.migrate }
  end

  def self.define_task(*args, &blk)
    Rake.application.define_task(self, *args, &blk)
  end
end
