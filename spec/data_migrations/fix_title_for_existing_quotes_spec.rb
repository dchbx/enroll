require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_title_for_existing_quotes")

describe FixTitleForExistingQuotes, dbclean: :around_each do

  let(:given_task_name) { "fix_title_for_existing_quotes" }
  subject { FixTitleForExistingQuotes.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "fix title for existing quotes", dbclean: :around_each do
    let(:broker_agency) { FactoryBot.create(:broker_agency_profile)}
    let(:plan_design_organization) { FactoryBot.create(:sponsored_benefits_plan_design_organization, :with_profile, owner_profile_id: broker_agency.id) }
    let(:proposal) { plan_design_organization.plan_design_proposals.first }
    let(:profile) do
      profile = proposal.profile
      profile.benefit_sponsorships = [FactoryBot.build(:plan_design_benefit_sponsorship)]
      profile.save
      profile
    end

    let(:benefit_sponsorship) { profile.benefit_sponsorships.first }
    let(:benefit_application) { FactoryBot.create(:plan_design_benefit_application, :with_benefit_group, benefit_sponsorship: benefit_sponsorship)}
    let(:plan) { FactoryBot.create(:plan, :with_premium_tables)}
    let!(:benefit_group) do
      bg = benefit_application.benefit_groups.first
      bg.relationship_benefits.build(relationship: "employee", premium_pct: 100)
      bg.assign_attributes(reference_plan_id: plan.id, elected_plans: [plan])
      bg.save!
      bg
    end

    it "should not have a title" do
      expect(benefit_group.title).to eq ""
    end

    it "should have title set on quote" do
      subject.migrate
      benefit_group.reload
      expect(benefit_group.title).not_to eq ""
    end
  end
end
