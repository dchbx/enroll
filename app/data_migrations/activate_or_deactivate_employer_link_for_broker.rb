require File.join(Rails.root, "lib/mongoid_migration_task")

class ActivateOrDeactivateEmpoyerLinkForBroker < MongoidMigrationTask
  def migrate
    begin
      fein_for_activate = ENV['activate_fein']
      fein_for_deactivate = ENV['deactivate_fein']
      active_plan_design_organizations = ::SponsoredBenefits::Organizations::PlanDesignOrganization.where(fein: fein_for_activate, has_active_broker_relationship: false)
      inactive_plan_design_organizations = ::SponsoredBenefits::Organizations::PlanDesignOrganization.where(fein: fein_for_deactivate, has_active_broker_relationship: true)

      if !(active_plan_design_organizations.present? || inactive_plan_design_organizations.present?)
        puts "No plan design organizations found for any of the feins" unless Rails.env.test?
        return
      elsif !((active_plan_design_organizations.present? && active_plan_design_organizations.count == 1) ||
        (inactive_plan_design_organizations.present? && inactive_plan_design_organizations.count == 1))
        puts "One of the plan design organizations are more than 1, ambiguity" unless Rails.env.test?
        return
      end

      if active_plan_design_organizations.present?
        active_organization = active_plan_design_organizations.first
        broker_agency_profile = ::BenefitSponsors::Organizations::Profile.find(active_organization.owner_profile_id) if active_organization.owner_profile_id.present?
        employer_profile = ::BenefitSponsors::Organizations::Profile.find(active_organization.sponsor_profile_id) if active_organization.sponsor_profile_id.present?
      end

      if active_organization && broker_agency_profile && employer_profile
        active_organization.update_attributes!(has_active_broker_relationship: true)
        puts "Successfully updated PlanDesignOrganization instance with fein: #{fein_for_activate}" unless Rails.env.test?
      else
        puts "No organization (or) broker_agency_profile (or) employer_profile found for the PlanDesignOrganization with fein: #{fein_for_activate}" unless Rails.env.test?
      end

      if inactive_plan_design_organizations.present?
        inactive_plan_design_organizations.first.update_attributes!(has_active_broker_relationship: false)
        puts "Successfully updated PlanDesignOrganization instance with fein: #{fein_for_deactivate}" unless Rails.env.test?
      end
    rescue => e
      puts "Error: #{e.backtrace}" unless Rails.env.test?
    end
  end
end
