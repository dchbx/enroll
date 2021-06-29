# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ActivateOrDeactivateEmployerLinkForBroker < MongoidMigrationTask
  def migrate
    plan_design_org_id = ENV['plan_design_org_id']
    plan_design_organization = ::SponsoredBenefits::Organizations::PlanDesignOrganization.find plan_design_org_id
    link_active = plan_design_organization.has_active_broker_relationship
    plan_design_organization.update_attributes!(has_active_broker_relationship: !link_active)
    puts "Successfully updated has_active_broker_relationship value to '#{!link_active}' for PlanDesignOrganization instance(bson_id: #{plan_design_org_id})" unless Rails.env.test?
  rescue StandardError => e
    puts "Error: #{e.backtrace}" unless Rails.env.test?
  end
end
