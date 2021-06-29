# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class RemovePlanOfferings < MongoidMigrationTask
  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    aasm_state = ENV['aasm_state']
    given_carrier_profile_id = ENV['carrier_profile_id'].to_s
    if organizations.size == 1
      org = organizations.first
      plan_year = org.employer_profile.plan_years.where(aasm_state: aasm_state).first
      bg = plan_year.benefit_groups.first

      if bg.present?

        tufts_plans, non_tufts_plans = bg.elected_plans.partition do |pln|
          pln.carrier_profile_id.to_s == given_carrier_profile_id
        end
        bg.elected_plan_ids = non_tufts_plans.map(&:id)
        bg.save!
        puts "removed the carrier from employer level offerings" unless Rails.env.test?
      else
        raise "no benefit group present."
      end
    else
      raise "issues with given fein"

    end
  rescue StandardError => e
    e.message
  end
end
