require File.join(Rails.root, "lib/mongoid_migration_task")
class RequestHavenTimeoutVerifications < MongoidMigrationTask
  def migrate
    FinancialAssistance::Application.determined.each do |application|
      begin
        application.check_verification_response
      rescue => e
        puts "Unable to send a request for Application: #{application.id} due to -- #{e}" unless Rails.env.test?
      end
    end
  end
end
