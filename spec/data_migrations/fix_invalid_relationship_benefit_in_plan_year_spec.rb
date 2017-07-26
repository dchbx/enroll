require "rails_helper"

require File.join(Rails.root, "app", "data_migrations", "fix_invalid_relationship_benefit_in_plan_year")
describe FixInvalidRelationshipBenefitInPlanYear, dbclean: :after_each do

  let(:given_task_name) { "set_child_over_26_relationship_false_in_plan_year" }
  subject { FixInvalidRelationshipBenefitInPlanYear.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "fix_invalid_relationship_benefit_in_plan_year" do

    context "set_child_over_26_relationship_false_in_plan_year" do
      let(:relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
            RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50),
            RelationshipBenefit.new(offered: true, relationship: :child_26_and_over, premium_pct: 50)
        ]
      end
      let!(:active_benefit_group) { FactoryGirl.create(:benefit_group,relationship_benefits:relationship_benefits)}
      let(:plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [active_benefit_group]) }
      let(:employer_profile) { FactoryGirl.build(:employer_profile, plan_years: [plan_year]) }
      let(:organization)      { FactoryGirl.create(:organization, employer_profile: employer_profile)}

      it "should return offered false for child_over_26_relationship" do
        child_over_26_relationship=organization.employer_profile.plan_years.first.benefit_groups.map(&:relationship_benefits).flatten.select{|r| r.relationship == "child_26_and_over"}.first
        expect(child_over_26_relationship.offered).to eq true #before update
        subject.migrate
        child_over_26_relationship.reload
        expect(child_over_26_relationship.offered).to eq false #after update
      end
    end
  end
end
