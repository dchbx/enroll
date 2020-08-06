# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateAptcDentalEnr < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id']).first
    enr_hbx_id = ENV['enr_hbx_id']
    if person.primary_family.present?
      enr = person.primary_family.enrollments.where(hbx_id: enr_hbx_id).first
      enr.update_attributes(applied_aptc_amount: 0.00) if enr.coverage_kind == "dental"
    end
    puts "Applied_aptc_amount on Dental Enrollment with hbx_id: #{enr_hbx_id} is: #{enr.applied_aptc_amount.to_f}" unless Rails.env.test?
  rescue StandardError
    puts "Bad Person Record" unless Rails.env.test?
  end
end
