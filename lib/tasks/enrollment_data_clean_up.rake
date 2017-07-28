# This rake task is to generate a list of enrollments satisfying the following scenario:
# Given a user has an active enrollment E1 with effective date X
# When the user purchases a new enrollment E2 with effective date Y
# And E2 is the same plan year
# And E2 is the same market type
# And E2 has the same subscriber
# E2 effective date > E1 effective date > E2 submitted on date.
# Then E1 is Canceled


require 'csv'
namespace :reports do
  desc "Report of enrollments placed in to the cancel state erroneously"
  task :list_of_enrollments_in_cancel_state_erroneously => :environment do
    file_name = "#{Rails.root}/enrollments_in_cancel_state_erroneously.csv"
    field_names  = ["HBX Subscriber ID",
                    "Cancel_enrollment_hbx_id",
                    "Cancel_enrollment_effective_date",
                    "Cancel_enrollment_market_type",
                    "Reference_enrollment_hbx_id"
                    ]
    CSV.open(file_name, "w") do |csv|
      csv << field_names
      families=Family.where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::CANCELED_STATUSES)
      families.each do |family|
        enrollments=family.active_household.hbx_enrollments
        break unless enrollments.size >= 2
        canceled_enrollments=enrollments.where(aasm_state:"coverage_canceled")
        break unless canceled_enrollments.size >= 1
        other_enrollments = enrollments - canceled_enrollments
        break unless other_enrollments.size > 0
        canceled_enrollments.each do |canceled_enrollment|
            kind = canceled_enrollment.kind
            next unless canceled_enrollment.subscriber
            person_id = canceled_enrollment.subscriber.person.id
            effective = canceled_enrollment.effective_on

            other_enrollments = other_enrollments.select{|a| a.subscriber  && a.effective_on  && a.submitted_at  }
            other_enrollments = other_enrollments.select{|a| a.kind == kind && a.subscriber.person.id == person_id  && effective > a.submitted_at && effective < a.effective_on }

            next unless other_enrollments.size > 0
            other_enrollments.each do |enrollment|
              if kind == "individual" && effective.year == enrollment.effective_on.year
                csv << [canceled_enrollment.subscriber.person.hbx_id,
                      canceled_enrollment.hbx_id,
                      canceled_enrollment.effective_on,
                      canceled_enrollment.kind,
                      enrollment.hbx_id
                      ]

              elsif kind == "employer_sponsored" && canceled_enrollment.benefit_group.plan_year == enrollment.benefit_group.plan_year
                csv << [canceled_enrollment.subscriber.person.hbx_id,
                      canceled_enrollment.hbx_id,
                      canceled_enrollment.effective_on,
                      canceled_enrollment.kind,
                      enrollment.hbx_id
                      ]
              end
            end
        end
      end
    end
  end
end



