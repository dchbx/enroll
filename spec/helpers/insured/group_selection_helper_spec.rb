require "rails_helper"

RSpec.describe Insured::GroupSelectionHelper, :type => :helper do
  let(:subject)  { Class.new { extend Insured::GroupSelectionHelper } }

  describe "#can shop individual" do
    let(:person) { FactoryGirl.create(:person) }

    it "should not have an active consumer role" do
      expect(subject.can_shop_individual?(person)).not_to be_truthy
    end

    context "with active consumer role" do
      let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
      it "should have active consumer role" do
        expect(subject.can_shop_individual?(person)).to be_truthy
      end

    end
  end

  describe "#can shop shop" do
    let(:person) { FactoryGirl.create(:person) }

    it "should not have an active employee role" do
        expect(subject.can_shop_shop?(person)).not_to be_truthy
    end
    context "with active employee role" do
      let(:person) { FactoryGirl.create(:person, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true) 
      end

      it "should have active employee role but no benefit group" do
        expect(subject.can_shop_shop?(person)).not_to be_truthy
      end

    end
    
    context "with active employee role and benefit group" do
      let(:person) { FactoryGirl.create(:person, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true) 
        allow(person).to receive(:has_employer_benefits?).and_return(true)
      end

      it "should have active employee role and benefit group" do
        expect(subject.can_shop_shop?(person)).to be_truthy
      end
    end

  end

  describe "#can shop both" do
    let(:person) { FactoryGirl.create(:person) }
    context "with active consumer role" do
      let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true) 
      end
      it "should have both active consumer and employee role" do
        expect(subject.can_shop_both_markets?(person)).not_to be_truthy
      end
    end
    
    context "with active consumer role" do
      let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_employee_role) }
      before do
        allow(person).to receive(:has_active_employee_role?).and_return(true) 
        allow(person).to receive(:has_employer_benefits?).and_return(true)
      end
      it "should have both active consumer and employee role" do
        expect(subject.can_shop_both_markets?(person)).to be_truthy
      end
    end

  end

  describe "#health_relationship_benefits" do

    context "active/renewal health benefit group offered relationships" do
      let(:employee_role){FactoryGirl.build(:employee_role)}
      let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group) }
      let!(:active_benefit_group) { FactoryGirl.create(:benefit_group)}

      let(:relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
            RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      it "should return offered relationships of active health benefit group" do
        allow(employee_role).to receive_message_chain(:census_employee, :renewal_published_benefit_group).and_return(active_benefit_group)
        allow(active_benefit_group).to receive_message_chain(:relationship_benefits).and_return(relationship_benefits)
        expect(subject.health_relationship_benefits(employee_role)).to eq ["employee", "spouse", "child_under_26"]
      end

      it "should return offered relationships of renewal health benefit group" do
        allow(employee_role).to receive_message_chain(:census_employee, :renewal_published_benefit_group).and_return(renewal_benefit_group)
        allow(renewal_benefit_group).to receive_message_chain(:relationship_benefits).and_return(relationship_benefits)
        expect(subject.health_relationship_benefits(employee_role)).to eq ["employee", "spouse", "child_under_26"]
      end
    end
  end

  describe "#dental_relationship_benefits" do

    context "active/renewal dental benefit group offered relationships" do
      let(:employee_role){FactoryGirl.build(:employee_role)}
      let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group) }
      let!(:active_benefit_group) { FactoryGirl.create(:benefit_group)}

      let(:dental_relationship_benefits) do
        [
            RelationshipBenefit.new(offered: true, relationship: :employee, premium_pct: 100),
            RelationshipBenefit.new(offered: true, relationship: :spouse, premium_pct: 75),
            RelationshipBenefit.new(offered: true, relationship: :child_under_26, premium_pct: 50)
        ]
      end

      it "should return offered relationships of active dental benefit group" do
        allow(employee_role).to receive_message_chain(:census_employee, :renewal_published_benefit_group).and_return(active_benefit_group)
        allow(active_benefit_group).to receive_message_chain(:dental_relationship_benefits).and_return(dental_relationship_benefits)
        expect(subject.dental_relationship_benefits(employee_role)).to eq ["employee", "spouse", "child_under_26"]
      end

      it "should return offered relationships of renewal dental benefit group" do
        allow(employee_role).to receive_message_chain(:census_employee, :renewal_published_benefit_group).and_return(renewal_benefit_group)
        allow(renewal_benefit_group).to receive_message_chain(:dental_relationship_benefits).and_return(dental_relationship_benefits)
        expect(subject.dental_relationship_benefits(employee_role)).to eq ["employee", "spouse", "child_under_26"]
      end
    end
  end
end
