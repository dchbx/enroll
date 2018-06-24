require File.join(Rails.root, "lib/mongoid_migration_task")

class TriggerDentalExitNotice < MongoidMigrationTask
  def migrate
    employer_groups = [Date.new(2018, 1, 1), Date.new(2018, 2, 1), Date.new(2018, 3, 1)]
    return "Provide an Array" unless employer_groups.kind_of?(Array)
    organizations = Organization.where(:"employer_profile.plan_years" => {:"$elemMatch" => 
      {
        :"start_on".in => employer_groups,
        :"aasm_state".in => PlanYear::RENEWING + ["renewing_application_ineligible", "renewing_canceled"]
      }
    })

    organizations.each do |organization|
      begin
        ShopNoticesNotifierJob.perform_later(organization.employer_profile.id.to_s, "employer_renewal_dental_carriers_exiting_notice")
      rescue Exception => e
        Rails.logger.error { "Unable to deliver #{notice_name} notice to employer #{@employer_profile.legal_name} due to #{e}" }
      end
    end
    puts "************* Trigger Finished *************" unless Rails.env.test?
  end
end
