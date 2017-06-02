#this rake task produces an csv report providing all OE enrollments have a timestamp
#to be an active OE IVL enrollment:
#1)special enrollment perid should be nil
#2)market type is individual
#3)workflow state transitions should not include auto_renewing
#4)effective on the first day of current year

require 'csv'
namespace :reports do
  namespace :individual do
    desc "All OE Enrollments that have timestamp"
    task :enrollments_with_timestamp => :environment do
      families = Family.where(:"households.hbx_enrollments.kind".in => ["individual"],
                              :"households.hbx_enrollments.special_enrollment_period_id"=>nil,
                              :"households.hbx_enrollments.effective_on"=> TimeKeeper.date_of_record.beginning_of_year
                              ).all
      field_names  = %w(primary_first_name
                        primary_last_name
                        primary_dob
                        primary_ssn
                        plan_selected
                        plan_type
                        plan_metal_level
                        submitted_at
                        )
      processed_count = 0
      file_name = "#{Rails.root}/enrollments_with_timestamp.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names

        families.each do |family|
          next unless family.active_household.present?
          household = family.active_household

          next unless household.hbx_enrollments.present?
          hbx_enrollments = household.hbx_enrollments
          hbx_enrollments.each do |hbx_enrollment|
            next unless hbx_enrollment.kind == "individual"
            next if hbx_enrollment.special_enrollment_period
            next unless hbx_enrollment.effective_on == TimeKeeper.date_of_record.beginning_of_year
            next if hbx_enrollment.workflow_state_transitions.map(&:to_state).include?("auto_renewing")
            next if hbx_enrollment.submitted_at

            next unless hbx_enrollment.subscriber && hbx_enrollment.subscriber.person
            person = hbx_enrollment.subscriber.person

            next unless hbx_enrollment.plan
            plan = hbx_enrollment.plan

            csv << [person.first_name,
                    person.last_name,
                    person.dob,
                    person.ssn,
                    plan.name,
                    plan.plan_type,
                    plan.metal_level,
                    hbx_enrollment.submitted_at
                   ]
            processed_count += 1

          end
        end
      end
      puts "#{processed_count} Enrollments to output file: #{file_name}"
    end
  end
end