# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class TriggeringAutoRenewalsForSpecificEmployer < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    raise 'Issues with given fein' if organizations.size != 1
    organizations.first.employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE).first.trigger_passive_renewals
    puts "Triggered auto-renewals for renewal plan year of #{organizations.first.legal_name}" unless Rails.env.test?
  end
end
