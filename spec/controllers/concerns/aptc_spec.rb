require 'rails_helper'

class FakesController < ApplicationController
  include Aptc
end

RSpec.describe FakesController, :type => :controller do

  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    allow(person).to receive_message_chain("primary_family.enrolled_hbx_enrollments").and_return([hbx_enrollment_one])
    allow(person).to receive(:primary_family).and_return(family)
  end

  let!(:person) {FactoryGirl.create(:person, :with_family, :with_consumer_role)}
  let!(:person1) { FactoryGirl.create(:person, :with_family, :with_consumer_role) }
  let!(:imt){IndividualMarketTransition.new(role_type: 'consumer', reason_code: 'generating_consumer_role', effective_starting_on: person.consumer_role.created_at.to_date, submitted_at: ::TimeKeeper.datetime_of_record)}
  let!(:imt1){IndividualMarketTransition.new(role_type: 'consumer', reason_code: 'generating_consumer_role', effective_starting_on: person1.consumer_role.created_at.to_date, submitted_at: ::TimeKeeper.datetime_of_record)}
  let!(:update_person) {person.individual_market_transitions << imt}
  let!(:update_person1) {person1.individual_market_transitions << imt1}
  let!(:family)  { person.primary_family}
  let!(:family2)  { person1.primary_family}
  let!(:current_date) {TimeKeeper.date_of_record}
  let(:application) { FactoryGirl.create(:application, family: family) }
  let(:hbx_enrollment_one) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household) }
  let(:hbx_enrollment2) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household1) }
  let!(:primary_member) { family.primary_applicant}
  let!(:primary_member1) { family2.primary_applicant}
  let!(:family_member1) { FactoryGirl.create(:family_member, family: family) }
  let!(:family_member2) { FactoryGirl.create(:family_member, family: family) }
  let!(:family_member3) { FactoryGirl.create(:family_member, family: family2) }
  let!(:family_member4) { FactoryGirl.create(:family_member, family: family2) }
  let!(:household) { family.households.first }
  let!(:household1) { family2.households.first }
  let!(:tax_household1) {FactoryGirl.create(:tax_household, application_id: application.id,  household: household, effective_ending_on: nil, effective_starting_on: current_date, is_eligibility_determined: true)}
  let!(:tax_household2) {FactoryGirl.create(:tax_household, application_id: application.id, household: household, effective_ending_on: nil, effective_starting_on: current_date, is_eligibility_determined: true)}
  let!(:tax_household3) {FactoryGirl.create(:tax_household, application_id: application.id, household: household, effective_ending_on: nil, effective_starting_on: current_date, is_eligibility_determined: true)}
  let!(:tax_household4) {FactoryGirl.create(:tax_household, household: household1, effective_ending_on: nil, effective_starting_on: current_date, is_eligibility_determined: true)}
  let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family.primary_applicant.id) }
  let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member1.id) }
  let!(:applicant3) { FactoryGirl.create(:applicant, tax_household_id: tax_household3.id, application: application, family_member_id: family_member2.id) }

  describe FakesController do
    context "#get_shopping_tax_household_from_person" do
      it "should get nil without person" do
        expect(subject.get_shopping_tax_households_from_person(nil, current_date.year)).to eq nil
      end

      it "should get taxhousehold with person" do
        expect(subject.get_shopping_tax_households_from_person(person, current_date.year).to_a).to eq [tax_household1, tax_household2, tax_household3]
      end

      it "should get nil when person without consumer_role" do
        allow(person).to receive(:is_consumer_role_active?).and_return false
        expect(subject.get_shopping_tax_households_from_person(person, current_date.year)).to eq nil
      end

      it "should get taxhousehold with application" do
        expect(subject.get_shopping_tax_households_from_person(person, current_date.year)).to eq application.active_determined_tax_households
      end

      it "should get taxhousehold with curram" do
        expect((subject.get_shopping_tax_households_from_person(person1, current_date.year)).to_a).to eq [tax_household4]
      end
    end

    describe "get_tax_household_from_family_members" do
      context "get_tax_household_from_family_members" do
        it "should return all the tax housholds of the given family members" do
          family_member_ids = [primary_member.id.to_s, family_member1.id.to_s, family_member2.id.to_s]
          expect(subject.get_tax_households_from_family_members(person, family_member_ids, current_date.year)).to eq [tax_household1, tax_household2, tax_household3]
        end

        it "should not return any tax housholds as the effective year is different" do
          allow(person).to receive(:has_active_consumer_role?).and_return true
          family_member_ids = [primary_member.id.to_s, family_member1.id.to_s, family_member2.id.to_s]
          expect(subject.get_tax_households_from_family_members(person, family_member_ids, 2014)).to eq []
        end

        it "should return no tax housholds for no family members" do
          expect(subject.get_tax_households_from_family_members(person, [], current_date.year)).to eq []
        end
      end

      context "total_aptc_on_tax_households" do
        it "should return 0 when there are no enrollments" do
          tax_households = [applicant1.tax_household, applicant3.tax_household]
          expect(subject.total_aptc_on_tax_households(tax_households, nil)).to eq 0
        end
      end
    end
  end
end
