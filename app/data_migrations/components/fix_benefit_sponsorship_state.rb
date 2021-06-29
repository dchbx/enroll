# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class FixBenefitSponsorshipState < MongoidMigrationTask
  def migrate
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.all.each do |benefit_sponsorship|
      next unless benefit_sponsorship.benefit_applications.any?(&:active?) && benefit_sponsorship.aasm_state != :active
      before_update = benefit_sponsorship.aasm_state
      benefit_sponsorship.aasm_state = :active
      benefit_sponsorship.save
      benefit_sponsorship.workflow_state_transitions << WorkflowStateTransition.new(from_state: before_update, to_state: :active)
      puts "Benefit Sponsorship state updated from #{before_update} to #{benefit_sponsorship.aasm_state}" unless Rails.env.test?
    end
  end
end
