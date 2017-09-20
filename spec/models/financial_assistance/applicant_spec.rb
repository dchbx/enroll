require 'rails_helper'

RSpec.describe FinancialAssistance::Applicant, type: :model do

  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:application) { FactoryGirl.create(:application, family: family) }
  let(:tax_filer_kind) { "single" }
  let(:has_fixed_address) { true }
  let(:strictly_boolean) { true }

  let(:valid_params){
      {
        application: application,
        tax_filer_kind: tax_filer_kind,
        has_fixed_address: has_fixed_address,
        strictly_boolean: strictly_boolean
      }
    }

    before(:each) do
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    end

  context "with wrong arguments" do
    let(:params) {{application: application, tax_filer_kind: "test", has_fixed_address: nil}}

    it "should not save" do
      expect(FinancialAssistance::Applicant.create(**params).valid?).to be_falsey
    end
  end

  describe "applicants for an application" do
    let!(:family)  { FactoryGirl.create(:family, :with_primary_family_member) }
    let!(:family_member1) { family.primary_applicant }
    let!(:person2) { FactoryGirl.create(:person, dob: "1972-04-04".to_date) }
    let!(:family_member2) { FactoryGirl.create(:family_member, family: family, person: person2) }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    let!(:tax_household1) {FactoryGirl.create(:tax_household, application: application, effective_ending_on: nil)}
    let!(:eligibility_determination1) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household1.id, source: "Curam", csr_eligibility_kind: "csr_87")}
    let!(:eligibility_determination2) {FactoryGirl.create(:eligibility_determination, application: application, tax_household_id: tax_household1.id, source: "Haven")}
    let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member1.id) }
    let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member2.id) }

    context "applicants with tax household and multiple eligibility_determinations" do

      it "should return only one eligibility determination and that should be preferred" do
        expect(applicant1.preferred_eligibility_determination).to eq eligibility_determination1
        expect(applicant1.preferred_eligibility_determination).not_to eq eligibility_determination2
      end

      it "should equal to the csr_eligibility_kind of preferred_eligibility_determination" do
        expect(application.current_csr_eligibility_kind(tax_household1.id)).to eq eligibility_determination1.csr_eligibility_kind
        expect(application.current_csr_eligibility_kind(tax_household1.id)).not_to eq eligibility_determination2.csr_eligibility_kind
      end

      it "should take eligibility determination with source Curam as preferred eligibility determination and not haven" do
        expect(applicant1.preferred_eligibility_determination.source).to eq "Curam"
        expect(applicant1.preferred_eligibility_determination.source).not_to eq "Haven"
      end

      it "should return al the eligibility determinations for that applicant" do
        expect(applicant1.eligibility_determinations).to eq [eligibility_determination1, eligibility_determination2]
        expect(applicant1.eligibility_determinations).not_to eq [eligibility_determination1, eligibility_determination1]
      end

      it "should return the dob of the person associated to the applicant" do
        expect(applicant2.age_on_effective_date).to eq 45
        expect(applicant2.age_on_effective_date).not_to eq 25
      end

      it "should return the right tax household for a given applicant" do
        expect(applicant1.tax_household).to eq tax_household1
        expect(applicant1.tax_household).not_to eq nil
      end

      it "should return right family_member and family" do
        expect(applicant1.family).to eq family
        expect(applicant1.family_member).to eq family_member1
        expect(applicant1.family_member).not_to eq family_member2
      end

      it "should return true if the family_member associated to the applicant is the primary of the family" do
        expect(applicant1.is_primary_applicant?).to eq true
        expect(applicant1.is_primary_applicant?).not_to eq false
      end
    end
  end
end
