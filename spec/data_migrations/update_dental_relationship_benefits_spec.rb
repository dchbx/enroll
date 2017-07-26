require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_dental_relationship_benefits")

describe "UpdateDentalRelationshipBenefits", dbclean: :after_each do

  let(:given_task_name) { "update_dental_relationship_benefits" }
  subject { UpdateDentalRelationshipBenefits.new(given_task_name, double(:current_scope => nil)) }


  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "change person relationships kind" do
    let!(:benefit_group)  {FactoryGirl.create(:benefit_group, :with_valid_dental)}
    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(benefit_group.employer_profile.organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(benefit_group.plan_year.start_on)
      allow(ENV).to receive(:[]).with("benefit_group_id").and_return(benefit_group.id)
      allow(ENV).to receive(:[]).with("relationship").and_return('spouse')
    end

    it "should change person relationships kind" do
      subject.migrate
      benefit_group.reload
      expect(benefit_group.dental_relationship_benefits.where(relationship:'spouse').first.offered).to eq false
    end
  end
end
