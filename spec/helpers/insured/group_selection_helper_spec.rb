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
end
