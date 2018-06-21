require 'rails_helper'
require 'aasm/rspec'

RSpec.describe FinancialAssistance::Application, type: :model do
  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    allow_any_instance_of(FinancialAssistance::Application).to receive(:create_verification_documents).and_return(true)
  end

  let!(:primary_member) { FactoryGirl.create(:person, :with_consumer_role) }
  let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member, person: primary_member) }
  let!(:person2) { FactoryGirl.create(:person, :with_consumer_role) }
  let!(:person3) { FactoryGirl.create(:person, :with_consumer_role) }
  let!(:person4) { FactoryGirl.create(:person, :with_consumer_role) }
  let!(:family_member1) { FactoryGirl.create(:family_member, family: family, person: person2) }
  let!(:family_member2) { FactoryGirl.create(:family_member, family: family, person: person3) }
  let!(:family_member3) { FactoryGirl.create(:family_member, family: family, person: person4) }
  let!(:year) { TimeKeeper.date_of_record.year }
  let!(:application) { FactoryGirl.create(:application, family: family) }
  let!(:household) { family.households.first }
  let!(:tax_household) { FactoryGirl.create(:tax_household, household: household) }
  let!(:tax_household1) { FactoryGirl.create(:tax_household, application_id: application.id, household: household, effective_ending_on: nil, is_eligibility_determined: true) }
  let!(:tax_household2) { FactoryGirl.create(:tax_household, application_id: application.id, household: household, effective_ending_on: nil, is_eligibility_determined: true) }
  let!(:tax_household3) { FactoryGirl.create(:tax_household, application_id: application.id, household: household) }
  let!(:eligibility_determination1) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household1) }
  let!(:eligibility_determination2) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household2) }
  let!(:eligibility_determination3) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household3) }
  let!(:application2) { FactoryGirl.create(:application, family: family, assistance_year: TimeKeeper.date_of_record.year, aasm_state: "denied") }
  let!(:application3) { FactoryGirl.create(:application, family: family, assistance_year: TimeKeeper.date_of_record.year, aasm_state: "determination_response_error") }
  let!(:application4) { FactoryGirl.create(:application, family: family, assistance_year: TimeKeeper.date_of_record.year) }
  let!(:application5) { FactoryGirl.create(:application, family: family, assistance_year: TimeKeeper.date_of_record.year) }
  let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family.primary_applicant.id) }
  let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member2.id) }
  let!(:applicant3) { FactoryGirl.create(:applicant, tax_household_id: tax_household3.id, application: application, family_member_id: family_member3.id) }

  describe "given applications for a family" do
    context "applications for a family with eligibility determinations, tax households and applicants" do

      it "should return all the applications for the family" do
        expect(family.applications.count).to eq 5
        expect(family.active_approved_application).to eq application5
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
        tax_household1.update_attributes(:effective_ending_on => nil)
        tax_household2.update_attributes(:effective_ending_on => nil)
        expect(application.latest_active_tax_households_with_year(year).count).to eq 2
        expect(application.latest_active_tax_households_with_year(year)).to eq [tax_household1, tax_household2]
      end

      it "should only return latest tax households of the application" do
        expect(application.latest_active_tax_households_with_year(year).count).not_to eq 3
        expect(application.latest_active_tax_households_with_year(year)).not_to eq [tax_household1, tax_household2, tax_household3]
      end

      it "should match the right eligibility determination for the tax household" do
        expect(application.eligibility_determinations[0]).to eq (eligibility_determination1)
        expect(application.eligibility_determinations[1]).to eq (eligibility_determination2)
        expect(application.eligibility_determinations[2]).to eq (eligibility_determination3)
      end

      it "should not return wrong eligibility determinations" do
        expect(application.eligibility_determinations_for_year(year).size).not_to eq 1
        ed1 = application.eligibility_determinations[0]
        expect(ed1).not_to eq eligibility_determination3
      end

      it "should return unique tax households where the active_approved_application's applicants are present" do
        expect(application.tax_households.count).to eq 3
        expect(application.tax_households).to eq [tax_household1, tax_household2,tax_household3]
      end

      it "should only return all unique tax_households" do
        expect(application.tax_households.count).not_to eq 2
        expect(application.tax_households).not_to eq [tax_household1, tax_household1, tax_household2]
      end

      it "should not return all tax_households" do
        expect(application.tax_households).not_to eq applicant1.tax_household.to_a
        expect(application.tax_households).not_to eq applicant1.tax_household.to_a
      end
    end

    context "current_csr_eligibility_kind" do

      it "should equal to the csr_eligibility_kind of preferred_eligibility_determination" do
        expect(application.current_csr_eligibility_kind(tax_household1.id)).to eq eligibility_determination1.csr_eligibility_kind
      end

      it "should return the right eligibility_determination based on the tax_household_id" do
        ed = application.eligibility_determinations[0]
        expect(ed).to eq eligibility_determination1
      end
    end

    context "check the validity of an application" do
      let!(:valid_application) { FactoryGirl.create(:application, family: family, hbx_id: "345332", applicant_kind: "user and/or family", request_kind: "request-kind",
                                                    motivation_kind: "motivation-kind", us_state: "DC", is_ridp_verified: true, assistance_year: TimeKeeper.date_of_record.year, aasm_state: "draft",
                                                    medicaid_terms: true, attestation_terms: true, submission_terms: true, medicaid_insurance_collection_terms: true,
                                                    report_change_terms: true, parent_living_out_of_home_terms: true, applicants: [applicant_primary]) }
      let!(:invalid_application) { FactoryGirl.create(:application, family: family, aasm_state: "draft", applicants: [applicant_primary2]) }

      let!(:applicant_primary) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member.id) }
      let!(:applicant_primary2) { FactoryGirl.create(:applicant, tax_household_id: tax_household2.id, application: application, family_member_id: family_member.id) }
      let!(:tax_household1) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}
      let!(:tax_household2) {FactoryGirl.create(:tax_household, household: household, effective_ending_on: nil)}
      let(:family_member) { FactoryGirl.create(:family_member, family: family, is_primary_applicant: true) }

      it "should allow a sucessful state transition if the application is valid" do
        allow(valid_application).to receive(:is_application_valid?).and_return(true)
        expect(valid_application.submit).to eq true
        expect(valid_application.determine).to eq true
        expect(valid_application.aasm_state).to eq "determined"
      end

      it "should invoke submit_application on a sucessful state transition on submit" do
        allow(valid_application).to receive(:is_application_valid?).and_return(true)
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

  describe "#set_assistance_year" do
    let(:assistance_year) { TimeKeeper.date_of_record + 1.year}
    let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    it "updates assistance year" do
      allow(application.family).to receive(:application_applicable_year).and_return(assistance_year.year)
      application.send(:set_assistance_year)
      expect(application.assistance_year).to eq(assistance_year.year)
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

  describe "generates hbx_id for application" do
    let(:new_family) { FactoryGirl.build(:family, :with_primary_family_member) }
    let(:new_application) { FactoryGirl.build(:application, family: new_family) }

    it "creates an hbx id if doesn't exists" do
      expect(new_application.hbx_id).to eq nil
      new_application.save
      expect(new_application.hbx_id).not_to eq nil
    end
  end

  describe "for create_tax_households" do

    before :each do
      application.update_attributes( family: family, hbx_id: "345334", applicant_kind: "user and/or family", request_kind: "request-kind",
                                     motivation_kind: "motivation-kind", us_state: "DC", is_ridp_verified: true, assistance_year: TimeKeeper.date_of_record.year, aasm_state: "draft",
                                     medicaid_terms: true, attestation_terms: true, submission_terms: true, medicaid_insurance_collection_terms: true,
                                     report_change_terms: true, parent_living_out_of_home_terms: true)
      allow(application).to receive(:is_application_valid?).and_return(true)
    end


    it "When there are two joint filers and one claimed as tax dependent - applicants looping order 1" do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: true, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true,claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: true, is_required_to_file_taxes: true)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq "tax_filer"
      expect(applicant2.tax_filer_kind).to eq "dependent"
      expect(applicant3.tax_filer_kind).to eq "tax_filer"
    end

    it "When there is one tax filers and two claimed as tax dependent - applicants looping order 2" do
      applicant1.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant3.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant3.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq "dependent"
      expect(applicant2.tax_filer_kind).to eq "dependent"
      expect(applicant3.tax_filer_kind).to eq "tax_filer"
    end

    it "When there is one tax filers and two claimed as tax dependent - applicants looping order 3" do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, claimed_as_tax_dependent_by: nil, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq "tax_filer"
      expect(applicant2.tax_filer_kind).to eq "dependent"
      expect(applicant3.tax_filer_kind).to eq "non_filer"
    end

    it "When there are two tax filers and one claimed as tax dependent - applicants looping order 4" do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant3.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq "tax_filer"
      expect(applicant2.tax_filer_kind).to eq "tax_filer"
      expect(applicant3.tax_filer_kind).to eq "dependent"
    end
  end
end