require 'csv'
namespace :reports do
  desc "Report of Enrollments (resulting from SEP/QLE) with missing SpecialEnrollmentPeriod ID"
  task :enrollments_missing_sep_id => :environment do
    file_name = "#{Rails.root}/enrollments_with_missing_sep_id.csv"
    field_names  = ["HBX Subscriber ID", 
                    "First Name", 
                    "Last Name",
                    "HBX Group Enrollment ID", 
                    "Enrollment created_at", 
                    "Enrollment updated_at", 
                    "Enrollment effective_on"
                    ]
    CSV.open(file_name, "w") do |csv|
      csv << field_names
      Family.batch_size(1000).no_timeout.all.each do |fam|
        hbx_enrollments = fam.active_household.hbx_enrollments.active.enrolled
        hbx_enrollments.each do |hbx|
          if hbx.enrollment_kind == "special_enrollment" && hbx.special_enrollment_period_id == nil
            person = hbx.household.family.primary_applicant.person
            csv << [person.hbx_id, 
                    person.first_name, 
                    person.last_name, 
                    hbx.hbx_id, 
                    hbx.created_at,
                    hbx.updated_at,
                    hbx.effective_on
                   ]
            print "*"
          end
        end
      end
    end
  end
end
