require 'rails_helper'
require 'aasm/rspec'

RSpec.describe FinancialAssistance::Application, type: :model do
  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end
  let(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:family_member1) { FactoryGirl.create(:family_member, family: family) }
  let(:family_member2) { FactoryGirl.create(:family_member, family: family) }
  let(:family_member3) { FactoryGirl.create(:family_member, family: family) }
  let(:year) { TimeKeeper.date_of_record.year }
  let!(:application) { FactoryGirl.create(:application, family: family) }
  let!(:tax_household1) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil)}
  let!(:tax_household2) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil)}
  let!(:tax_household3) {FactoryGirl.create(:tax_household, application: application)}
  let!(:eligibility_determination1) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household1.id, csr_eligibility_kind: "csr_87", determined_on: TimeKeeper.date_of_record)}
  let!(:eligibility_determination2) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household2.id)}
  let!(:eligibility_determination3) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household3.id)}
  let!(:application2) { FactoryGirl.create(:application, family: family, assistance_year: 2016, aasm_state: "denied") }
  let!(:application3) { FactoryGirl.create(:application, family: family, assistance_year: 2016, aasm_state: "verifying_income") }
  let!(:application4) { FactoryGirl.create(:application, family: family, assistance_year: 2016) }
  let!(:application5) { FactoryGirl.create(:application, family: family, assistance_year: 2016) }
  let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member1.id) }
  let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member2.id) }
  let!(:applicant3) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member3.id) }


  describe "given applications for a family" do
    context "applications for a family with eligibility determinations, tax households and applicants" do

      it "should return all the applications for the family" do
        expect(family.applications.count).to eq 5
        expect(family.active_approved_application).to eq application
      end

      it "should return all the apporved applications for the family" do
        expect(family.approved_applications.count).to eq 3
        family.approved_applications.each do |ap|
          expect(family.approved_applications).to include(ap)
        end
      end

      it "should only return all the apporved applications for the family and not all" do
        expect(family.approved_applications.count).not_to eq 5
        expect(family.approved_applications).not_to eq [application, application2, application3]
      end

      it "should return all the eligibility determinations of the application" do
        expect(application.eligibility_determinations_for_year(year).size).to eq 3
        application.eligibility_determinations_for_year(year).each do |ed|
          expect(application.eligibility_determinations_for_year(year)).to include(ed)
        end
      end

      it "should return all the tax households of the application" do
        expect(application.tax_households.count).to eq 3
        expect(application.tax_households).to eq [tax_household1, tax_household2, tax_household3]
      end

      it "should not return wrong number of tax households of the application" do
        expect(application.tax_households.count).not_to eq 4
        expect(application.tax_households).not_to eq [tax_household1, tax_household2]
      end

      it "should return the latest tax households" do
        expect(application.latest_active_tax_households_with_year(year).count).to eq 2
        expect(application.latest_active_tax_households_with_year(year)).to eq [tax_household1, tax_household2]
      end

      it "should only return latest tax households of the application" do
        expect(application.latest_active_tax_households_with_year(year).count).not_to eq 3
        expect(application.latest_active_tax_households_with_year(year)).not_to eq [tax_household1, tax_household2, tax_household3]
      end

      it "should match the right eligibility determination for the tax household" do
        ed1 = application.eligibility_determinations.where(tax_household_id: tax_household1.id).first
        ed2 = application.eligibility_determinations.where(tax_household_id: tax_household2.id).first
        ed3 = application.eligibility_determinations.where(tax_household_id: tax_household3.id).first
        expect(ed1).to eq eligibility_determination1
        expect(ed2).to eq eligibility_determination2
        expect(ed3).to eq eligibility_determination3
      end

      it "should not return wrong eligibility determinations" do
        expect(application.eligibility_determinations_for_year(year).size).not_to eq 1
        ed1 = application.eligibility_determinations.where(tax_household_id: tax_household1.id).first
        expect(ed1).not_to eq eligibility_determination3
      end

      it "should return unique tax households where the active_approved_application's applicants are present" do
        expect(application.all_tax_households.count).to eq 2
        expect(application.all_tax_households).to eq [tax_household1, tax_household2]
      end

      it "should only return all unique tax_households" do
        expect(application.all_tax_households.count).not_to eq 3
        expect(application.all_tax_households).not_to eq [tax_household1, tax_household1, tax_household2]
      end

      it "should not return all tax_households" do
        expect(application.all_tax_households).not_to eq application.tax_households
        expect(application.all_tax_households).not_to eq [tax_household1, tax_household2, tax_household3]
      end
    end

    context "current_csr_eligibility_kind" do

      it "should equal to the csr_eligibility_kind of preferred_eligibility_determination" do
        expect(application.current_csr_eligibility_kind(tax_household1.id)).to eq eligibility_determination1.csr_eligibility_kind
      end

      it "should return the right eligibility_determination based on the tax_household_id" do
        ed = application.eligibility_determinations.where(tax_household_id: tax_household1.id).first
        expect(ed).to eq eligibility_determination1
      end
    end

    context "check the validity of an application" do
      let!(:valid_application) { FactoryGirl.create(:application, family: family, hbx_id: "345332", applicant_kind: "user and/or family", request_kind: "request-kind",
                                                    motivation_kind: "motivation-kind", us_state: "DC", is_ridp_verified: true, assistance_year: 2017, aasm_state: "draft",
                                                    medicaid_terms: true, attestation_terms: true, submission_terms: true, medicaid_insurance_collection_terms: true,
                                                    report_change_terms: true, parent_living_out_of_home_terms: true, applicants: [applicant_primary]) }
      let!(:invalid_application) { FactoryGirl.create(:application, family: family, aasm_state: "draft", applicants: [applicant_primary2]) }

      let!(:applicant_primary) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member.id) }
      let!(:applicant_primary2) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member.id) }
      let!(:tax_household1) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil)}
      let!(:tax_household2) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil)}
      let(:family_member) { FactoryGirl.create(:family_member, family: family, is_primary_applicant: true) }

      it "should allow a sucessful state transition if the application is valid" do
        expect(valid_application.submit).to eq true
        expect(valid_application.aasm_state).to eq "submitted"
      end

      it "should invoke submit_application on a sucessful state transition on submit" do
        expect(valid_application).to receive(:set_submit)
        valid_application.submit!
      end

      it "should not invoke submit_application on a submit of an invalid application" do
        expect(invalid_application).to_not receive(:set_submit)
        invalid_application.submit!
      end

      it "should prevent the state transition to happen and report invalid if the application is invalid" do
        invalid_application.update_attributes!(hbx_id: nil)
        expect(invalid_application).to receive(:report_invalid)
        invalid_application.submit!
        expect(invalid_application.aasm_state).to eq "draft"
      end

      it "should record transition on a valid application submit" do
        expect(valid_application).to receive(:record_transition)
        valid_application.submit!
      end

      it "should record transition on an invalid application submit" do
        expect(invalid_application).to receive(:record_transition)
        invalid_application.submit!
      end
    end
  end

  describe "trigger eligibility notice" do
    let(:family_member) { FactoryGirl.create(:family_member, family: family, is_primary_applicant: true) }
    let!(:applicant) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member.id) }
    before do
      application.update_attributes(:aasm_state => "submitted")
    end

    it "on event determine and family totally eligibile" do
      expect(application.is_family_totally_ineligibile).to eq false
      expect(application).to receive(:trigger_eligibilility_notice)
      application.determine!
    end
  end

  describe "trigger ineligibilility notice" do
    let(:family_member) { FactoryGirl.create(:family_member, family: family, is_primary_applicant: true) }
    let!(:applicant) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member.id) }
    before do
      application.active_applicants.each do |applicant|
        applicant.is_totally_ineligible = true
        applicant.save!
      end
      application.update_attributes(:aasm_state => "submitted")
    end

    it "event determine and family totally ineligibile" do
      expect(application.is_family_totally_ineligibile).to eq true
      expect(application).to receive(:trigger_eligibilility_notice)
      application.determine!
    end
  end
end