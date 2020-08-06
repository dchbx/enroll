# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class FixTitleForExistingQuotes < MongoidMigrationTask

  def plan_design_organization(proposal_id)
    Rails.cache.fetch("plan_design_proposal_#{proposal_id}", expires_in: 1.hour) do
      SponsoredBenefits::Organizations::PlanDesignOrganization.where(
        :"plan_design_proposals._id" => BSON::ObjectId.from_string(proposal_id)
      ).first
    end
  end

  def plan_design_proposal(id)
    plan_design_organization(id).plan_design_proposals.where(id: BSON::ObjectId.from_string(id)).first
  end

  def migrate
    SponsoredBenefits::Organizations::PlanDesignOrganization.collection.aggregate([
      {"$unwind" => "$plan_design_proposals" },
      {"$unwind" => "$plan_design_proposals.profile" },
      {"$unwind" => "$plan_design_proposals.profile.benefit_sponsorships" },
      {"$unwind" => "$plan_design_proposals.profile.benefit_sponsorships.benefit_applications" },
      {"$unwind" => "$plan_design_proposals.profile.benefit_sponsorships.benefit_applications.benefit_groups" },
      {"$match" => {"plan_design_proposals.profile.benefit_sponsorships.benefit_applications.benefit_groups.title" => {"$in" => [nil, ""]}}},
      {"$group" => {
        "_id" => {
          plan_design_proposal_id: "$plan_design_proposals._id",
          benefit_application_id: "$plan_design_proposals.profile.benefit_sponsorships.benefit_applications._id",
          benefit_group_id: "$plan_design_proposals.profile.benefit_sponsorships.benefit_applications.benefit_groups._id"
        }
      }},
      {"$project" => {
        plan_design_proposal_id: "$_id.plan_design_proposal_id",
        benefit_application_id: "$_id.benefit_application_id",
        benefit_group_id: "$_id.benefit_group_id"
      }}
    ]).each do |record|

      sponsorship = plan_design_proposal(record['plan_design_proposal_id']).profile.benefit_sponsorships.first
      application = sponsorship.benefit_applications.where(:id => record['benefit_application_id']).first
      benefit_group = application.benefit_groups.where(:id => record['benefit_group_id']).first
      title = "Benefit Group Created for: #{plan_design_organization(record['plan_design_proposal_id']).legal_name} by #{plan_design_organization(record['plan_design_proposal_id']).broker_agency_profile.legal_name}"
      if benefit_group.update_attributes(title: title)
        puts "Success: Title updated for Benefit Group Id:#{record['benefit_group_id']} belongs to #{plan_design_organization(record['plan_design_proposal_id']).legal_name}" unless Rails.env.test?
      else
        puts "Failure: Update Failed for benefit_group: #{record['benefit_group_id']} for PlanDesignOrganization: #{plan_design_organization(record['plan_design_proposal_id']).legal_name} with Errors: #{benefit_group.errors.full_messages}"
      end
    rescue Exception => e
      puts "Error: Failed for benefit group id: #{record['benefit_group_id']} for plan_design_proposal_id: #{record['plan_design_proposal_id']}: #{e}"

    end
  end
end
