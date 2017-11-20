require File.join(Rails.root, "lib/mongoid_migration_task")

class AddEnrollment < MongoidMigrationTask
  def migrate
    ts = TranscriptGenerator.new
    ts.display_enrollment_transcripts
    rescue Exception => e
     	puts e.message
    end
end