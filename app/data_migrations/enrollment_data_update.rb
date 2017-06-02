require File.join(Rails.root, "lib/mongoid_migration_task")

class EnrollmentDataUpdate < MongoidMigrationTask
  def migrate
    # This rake task is to generate a list of enrollments satisfying the following scenario:
    # Given a user has an active enrollment E1 with effective date X
    # When the user purchases a new enrollment E2 with effective date Y
    # And E2 is the same plan year
    # And E2 is the same market type
    # And E2 has the same subscriber
    # E2 effective date > E1 effective date > E2 submitted on date.
    # Then E1 is Canceled
    #IVL Enrollments should be transitioned from the Canceled state to the Terminated state.
    #SHOP Enrollments should be transitioned from the Canceled state to the Termination_Pending if coverage end date is in the future,
    #otherwise they should be transitioned to Terminated state.                                                                                                                                                                                                                                                                                  require 'csv'
    families=Family.where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::CANCELED_STATUSES)
    families.each do |family|
        begin
          enrollments=family.active_household.hbx_enrollments
          active_enrollments = enrollments.active
          canceled_enrollments, enrs = enrollments.partition{|enr| enr.aasm_state == "coverage_canceled"}
          canceled_enrollments.each do |e1|
            active_enrollments.each do |e2|
              if e1.present? && e2.present? && e1.kind != "coverall" && e2.kind != "coverall"
                e1_year = e1.kind == "individual" ? e1.effective_on.year : (e1.benefit_group.present? ? e1.benefit_group.plan_year.start_on.year.to_i : nil)
                e2_year = e2.kind == "individual" ? e2.effective_on.year : (e2.benefit_group.present? ? e2.benefit_group.plan_year.start_on.year.to_i : nil)
                next if e1.subscriber.nil? || e2.subscriber.nil?
                if e1.kind == e2.kind && e1_year == e2_year && e1.subscriber.applicant_id == e2.subscriber.applicant_id
                  if e1.effective_on > e2.submitted_at && e1.effective_on < e2.effective_on
                    aasm_state = "coverage_terminated"
                    aasm_state = "coverage_termination_pending" if e1.terminated_on.present? && e1.terminated_on > TimeKeeper.datetime_of_record
                    e1.update_attributes(aasm_state: aasm_state) if e1.aasm_state != aasm_state
                  end
                end
              end
            end
          end
        rescue Exception => e
          puts "#{e.message} :: family id is #{family.id}"
        end
      end
  end
end