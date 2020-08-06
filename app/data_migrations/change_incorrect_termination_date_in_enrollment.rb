# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
require 'date'
class ChangeIncorrectTerminationDateInEnrollment < MongoidMigrationTask

  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s).first
    new_termination_date = Date.strptime(ENV['termination_date'],'%m/%d/%Y').to_date

    if enrollment.nil?
      puts "No enrollment with given hbx_id was found" unless Rails.env.test?
    end
    enrollment.update_attributes(terminated_on: new_termination_date)
    enrollment.update_attributes(aasm_state: "coverage_terminated") if enrollment.aasm_state != "coverage_terminated"
  rescue Exception => e
    puts e.message
  end
end
