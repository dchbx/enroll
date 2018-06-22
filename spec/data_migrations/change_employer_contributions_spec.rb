require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_employer_contributions")

describe ChangeEmployerContributions, dbclean: :after_each do

  let(:given_task_name) { "change_employer_contributions" }
  let(:plan_year)         { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
  let(:employer_profile)  { FactoryGirl.create(:employer_profile) }

  subject { ChangeEmployerContributions.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing employer contributions for health benefits" do
    let(:benefit_group)     { FactoryGirl.create(:benefit_group, plan_year: plan_year)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      allow(ENV).to receive(:[]).with("relationship").and_return(benefit_group.relationship_benefits.first.relationship)
      allow(ENV).to receive(:[]).with("premium").and_return(benefit_group.relationship_benefits.first.premium_pct + 5)
      allow(ENV).to receive(:[]).with("offered").and_return(benefit_group.relationship_benefits.first.offered)
      allow(ENV).to receive(:[]).with("coverage_kind").and_return("health")
    end

    it "should change the employee contribution" do
      expect(benefit_group.relationship_benefits.first.premium_pct).to eq 80
      subject.migrate
      benefit_group.reload
      expect(benefit_group.relationship_benefits.first.premium_pct).to eq 85
    end

    it "should not change the other relationships contributions" do
      expect(benefit_group.relationship_benefits[1].premium_pct).to eq 40
      subject.migrate
      benefit_group.reload
      expect(benefit_group.relationship_benefits[1].premium_pct).to eq 40
    end

    it "should offer benefits" do
      benefit_group.relationship_benefits.first.update_attribute(:offered, false)
      subject.migrate
      benefit_group.reload
      expect(benefit_group.relationship_benefits.first.offered).to eq true
    end

    it "should not offer benefits for other relationships" do
      benefit_group.relationship_benefits[1].update_attribute(:offered, false)
      subject.migrate
      benefit_group.reload
      expect(benefit_group.relationship_benefits[1].offered).to eq false
    end
  end

  describe "changing employer contributions for dental benefits" do
    
    let(:benefit_group)     { FactoryGirl.create(:benefit_group, :with_dental_benefits, plan_year: plan_year)}

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(employer_profile.parent.fein)
      allow(ENV).to receive(:[]).with("aasm_state").and_return(plan_year.aasm_state)
      allow(ENV).to receive(:[]).with("relationship").and_return(benefit_group.dental_relationship_benefits.first.relationship)
      allow(ENV).to receive(:[]).with("premium").and_return(benefit_group.dental_relationship_benefits.first.premium_pct + 5)
      allow(ENV).to receive(:[]).with("offered").and_return(benefit_group.dental_relationship_benefits.first.offered)
      allow(ENV).to receive(:[]).with("coverage_kind").and_return("dental")
    end

    it "should change the employee contribution" do
      expect(benefit_group.dental_relationship_benefits.first.premium_pct).to eq 49
      subject.migrate
      benefit_group.reload
      expect(benefit_group.dental_relationship_benefits.first.premium_pct).to eq 54
    end

    it "should not change the other relationships contributions" do
      expect(benefit_group.dental_relationship_benefits[1].premium_pct).to eq 40
      subject.migrate
      benefit_group.reload
      expect(benefit_group.dental_relationship_benefits[1].premium_pct).to eq 40
    end

    it "should offer benefits" do
      benefit_group.dental_relationship_benefits.first.update_attribute(:offered, false)
      subject.migrate
      benefit_group.reload
      expect(benefit_group.relationship_benefits.first.offered).to eq true
    end

    it "should not offer benefits for other relationships" do
      benefit_group.dental_relationship_benefits[1].update_attribute(:offered, false)
      subject.migrate
      benefit_group.reload
      expect(benefit_group.dental_relationship_benefits[1].offered).to eq false
    end
  end
end
