require 'csv'
namespace :migrations do
  desc "Enrollment Cleanup for Renewal based on CSV file"
  task :enrollment_cleanup_for_renewal => :environment do
    CSV.foreach("#{Rails.root}/EnrollmentList.csv", headers: true) do |row|
      hbx_id = row['PolicyID']
      date = (row['date'].to_date).strftime("%m/%d/%Y")
      enrollment = HbxEnrollment.by_hbx_id(hbx_id).first
      if enrollment.nil?
        puts "no enrollment was found with hbx_id #{hbx_id}"
      elsif row["Action"].downcase == "cancel"
        enrollment.update_attributes!(terminated_on: date, aasm_state:"coverage_canceled")
        puts "cancel enrollment for policy with hbx_id #{hbx_id}" unless Rails.env.test?
      elsif row["Action"].downcase == "termination"
        enrollment.update_attributes!(terminated_on: date, aasm_state: "coverage_terminated")
        puts "terminate enrollment for policy with hbx_id #{hbx_id} for date #{date}" unless Rails.env.test?
      else
        puts "Invalid action for hbx_id #{hbx_id}" unless Rails.env.test?
      end
    end
  end
end