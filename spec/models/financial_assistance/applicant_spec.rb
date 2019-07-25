require 'rails_helper'

RSpec.describe FinancialAssistance::Applicant, type: :model do
  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

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

  describe "applicants for an application", dbclean: :after_each do
    let!(:person1) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:person2) { FactoryGirl.create(:person, :with_consumer_role, dob: "1972-04-04".to_date) }
    let!(:family)  {  family = FactoryGirl.create(:family, :with_primary_family_member, person: person1)
                      FactoryGirl.create(:family_member, family: family, person: person2)
                      person1.person_relationships.create!(successor_id: person2.id, predecessor_id: person1.id, kind: "spouse", family_id: family.id)
                      person2.person_relationships.create!(successor_id: person1.id, predecessor_id: person2.id, kind: "spouse", family_id: family.id)
                      family.save!
                      family }
    let!(:family_member1) { family.primary_applicant }
    let!(:family_member2) { family.family_members.second }
    let!(:application) { FactoryGirl.create(:application, family: family) }
    let!(:household) { family.households.first }
    let(:coverage_household1) { household.coverage_households.first }
    let(:coverage_household2) { household.coverage_households.second }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: household, aasm_state: "coverage_selected", coverage_household_id: household.coverage_households.first.id) }
    let!(:hbx_enrollment_member) { FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member1.id, eligibility_date: TimeKeeper.date_of_record) }
    let!(:tax_household1) { FactoryGirl.create(:tax_household,  application_id: application.id, household: household, effective_ending_on: nil) }
    let!(:eligibility_determination1) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household1, source: "Curam", csr_eligibility_kind: "csr_87") }
    let!(:eligibility_determination2) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household1, source: "Haven") }
    let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member1.id) }
    let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member2.id, aasm_state: "verification_outstanding") }
    let!(:assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant1, status: "pending") }

    before :each do
      coverage_household1.update_attributes!(aasm_state: "enrolled")
      coverage_household2.update_attributes!(aasm_state: "enrolled")
    end

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
        now = TimeKeeper.date_of_record
        dob = applicant2.person.dob
        current_age = now.year - dob.year - (now.strftime('%m%d') < dob.strftime('%m%d') ? 1 : 0)
        expect(applicant2.age_on_effective_date).to eq current_age
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

    context "state transitions and eligibility notification for hbx_enrollment and coverage_household" do

      context "from state unverified" do
        it "should return unverified state as a default state" do
          expect(applicant1.aasm_state).to eq "unverified"
        end

        context "for notify_of_eligibility_change and aasm_state changes on_event: income_outstanding, verification_outstanding" do
          before :each do
            applicant1.income_outstanding!
          end

          it "should transition from unverified to verification_outstanding" do
            expect(applicant1.aasm_state).to eq "verification_outstanding"
          end

          it "should also transition from enrolled to unverified for CoverageHousehold" do
            coverage_household1.reload
            expect(coverage_household1.aasm_state).to eq "unverified"
          end

          it "should also transition from coverage_selected to enrolled_contingent for HbxEnrollment" do
            hbx_enrollment.reload
            expect(hbx_enrollment.aasm_state).to eq "enrolled_contingent"
          end

          it "should also add the transition to workflow_state_transitions of the applicant" do
            expect(applicant1.workflow_state_transitions.last.from_state).to eq "unverified"
            expect(applicant1.workflow_state_transitions.last.to_state).to eq "verification_outstanding"
          end
        end

        context "for notify_of_eligibility_change and aasm_state changes on_event: income_valid, verification_pending" do
          before :each do
            applicant1.income_valid!
          end

          it "should transition from unverified to verification_outstanding" do
            expect(applicant1.aasm_state).to eq "verification_pending"
          end

          it "should also transition from enrolled to unverified for CoverageHousehold" do
            coverage_household1.reload
            expect(coverage_household1.aasm_state).to eq "unverified"
          end

          it "should also transition from coverage_selected to enrolled_contingent for HbxEnrollment" do
            hbx_enrollment.reload
            expect(hbx_enrollment.aasm_state).to eq "enrolled_contingent"
          end

          it "should also add the transition to workflow_state_transitions of the applicant" do
            expect(applicant1.workflow_state_transitions.last.from_state).to eq "unverified"
            expect(applicant1.workflow_state_transitions.last.to_state).to eq "verification_pending"
          end
        end


        context "for notify_of_eligibility_change and aasm_state changes on_event: income_valid, fully_verified" do
          let!(:assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant1, verification_type: "MEC", status: "verified" ) }

          before :each do
            applicant1.income_valid!
          end

          it "should transition from unverified to verification_outstanding" do
            expect(applicant1.aasm_state).to eq "fully_verified"
          end

          it "should also transition from enrolled to enrolled_contingent for CoverageHousehold" do
            coverage_household1.reload
            expect(coverage_household1.aasm_state).to eq "enrolled_contingent"
          end

          it "should also transition from coverage_selected to enrolled_contingent for HbxEnrollment" do
            hbx_enrollment.reload
            expect(hbx_enrollment.aasm_state).to eq "enrolled_contingent"
          end

          it "should also add the transition to workflow_state_transitions of the applicant" do
            expect(applicant1.workflow_state_transitions.last.from_state).to eq "unverified"
            expect(applicant1.workflow_state_transitions.last.to_state).to eq "fully_verified"
          end
        end
      end

      context "from state verification_outstanding" do
        it "should transition to verification_outstanding" do
          expect(applicant2.aasm_state).to eq "verification_outstanding"
          applicant2.income_outstanding!
          expect(applicant2.aasm_state).to eq "verification_outstanding"
        end

        it "should transition to fully_verified" do
          applicant2.assisted_verifications.create!(applicant: applicant2, verification_type: "MEC", status: "verified")
          expect(applicant2.aasm_state).to eq "verification_outstanding"
          applicant2.income_valid!
          expect(applicant2.aasm_state).to eq "fully_verified"
        end
      end

      context "from state verification_pending" do

        before :each do
          applicant2.update_attributes!(aasm_state: "verification_pending")
        end

        it "should transition to verification_outstanding" do
          expect(applicant2.aasm_state).to eq "verification_pending"
          applicant2.income_outstanding!
          expect(applicant2.aasm_state).to eq "verification_outstanding"
        end

        it "should transition to fully_verified" do
          applicant2.assisted_verifications.create!(applicant: applicant2, verification_type: "MEC", status: "verified")
          expect(applicant2.aasm_state).to eq "verification_pending"
          applicant2.income_valid!
          expect(applicant2.aasm_state).to eq "fully_verified"
        end
      end

      context "from fully_verified" do

        it "should transition to fully_verified" do
          applicant2.update_attributes!(aasm_state: "fully_verified")
          expect(applicant2.aasm_state).to eq "fully_verified"
          applicant2.income_valid!
          expect(applicant2.aasm_state).to eq "fully_verified"
        end
      end
    end

    context "validation of an Applicant in submission context" do
      driver_qns = FinancialAssistance::Applicant::DRIVER_QUESTION_ATTRIBUTES

      before(:each) do
        allow_any_instance_of(FinancialAssistance::Applicant).to receive(:is_required_to_file_taxes).and_return(true)
        allow_any_instance_of(FinancialAssistance::Applicant).to receive(:is_claimed_as_tax_dependent).and_return(false)
        allow_any_instance_of(FinancialAssistance::Applicant).to receive(:is_joint_tax_filing).and_return(false)
        allow_any_instance_of(FinancialAssistance::Applicant).to receive(:is_pregnant).and_return(false)
        allow_any_instance_of(FinancialAssistance::Applicant).to receive(:is_self_attested_blind).and_return(false)
        allow_any_instance_of(FinancialAssistance::Applicant).to receive(:has_daily_living_help).and_return(false)
        allow_any_instance_of(FinancialAssistance::Applicant).to receive(:need_help_paying_bills).and_return(false)
        applicant1.update_attributes!(is_required_to_file_taxes: true, is_joint_tax_filing: true, has_job_income: true)
        driver_qns.each { |attribute|  applicant1.send("#{attribute}=", false) }
      end

      driver_qns.each do |attribute|
        instance_check_method = attribute.to_s.gsub('has_', '') + "_exists?"

        it "should NOT validate applicant when #{attribute} is nil" do
          applicant1.send("#{attribute}=", nil)
          expect(applicant1.applicant_validation_complete?).to eq false
        end

        it "should validate applicant when some Driver Question attribute is FALSE and there is No Instance of that type" do
          applicant1.send("#{attribute}=", false)
          allow(applicant1).to receive(instance_check_method).and_return false
          expect(applicant1.applicant_validation_complete?).to eq true
        end

        it "should NOT validate applicant when some Driver Question attribute is TRUE but there is No Instance of that type" do
          applicant1.send("#{attribute}=", true)
          allow(applicant1).to receive(instance_check_method).and_return false
          expect(applicant1.applicant_validation_complete?).to eq false
        end

        it "should NOT validate applicant when some Driver Question attribute is FALSE but there is an Instance of that type" do
          applicant1.send("#{attribute}=", false)
          allow(applicant1).to receive(instance_check_method).and_return true
          expect(applicant1.applicant_validation_complete?).to eq false
        end

        it "should validate applicant for former_foster_care, if age is between 18 and 25 and is_former_foster_care is not nil" do
          applicant1.send("#{attribute}=", false)
          now = TimeKeeper.date_of_record
          applicant1.person.dob = Date.new((now.year - 20) ,1,1)
          expect(applicant1.is_former_foster_care).to eq nil
          applicant1.update_attributes!(is_former_foster_care: true)
          expect(applicant1.applicant_validation_complete?).to eq true
        end

        it "should validate applicant for former_foster_care, if age is between 18 and 25 and is_former_foster_care is nil" do
          applicant1.send("#{attribute}=", false)
          now = TimeKeeper.date_of_record
          applicant1.person.dob = Date.new((now.year - 20) ,1,1)
          expect(applicant1.is_former_foster_care).to eq nil
          expect(applicant1.applicant_validation_complete?).to eq false
        end

        it "should not validate applicant for former_foster_care, if age is not between 18 and 25" do
          applicant1.send("#{attribute}=", false)
          now = TimeKeeper.date_of_record
          applicant1.person.dob = Date.new((now.year - 30) ,1,1)
          expect(applicant1.is_former_foster_care).to eq nil
          expect(applicant1.applicant_validation_complete?).to eq true
        end
      end
    end

    context ".presence_of_attr_step_1" do

      it "applicant must answer is filing jointly if filing taxes & has spouse" do
        allow(applicant1).to receive(:is_required_to_file_taxes).and_return(true)
        applicant1.send(:presence_of_attr_step_1)
        expect(applicant1.errors[:is_joint_tax_filing].first).to include("Will this person be filling jointly?' can't be blank")
      end

      it "applicant must file taxes if spouse is filing jointly" do
        allow(applicant2).to receive(:is_joint_tax_filing).and_return(true)
        allow(applicant1).to receive(:is_required_to_file_taxes).and_return(false)
        applicant1.send(:presence_of_attr_step_1)
        expect(applicant1.errors["is_joint_tax_filing"].first).to include("Both spouses must have the same filing status if filing jointly")
      end

      it "applicant must file taxes jointly if spouse is filing jointly" do
        allow(applicant2).to receive(:is_joint_tax_filing).and_return(true)
        allow(applicant1).to receive(:is_required_to_file_taxes).and_return(true)
        allow(applicant1).to receive(:is_joint_tax_filing).and_return(false)
        applicant1.send(:presence_of_attr_step_1)
        expect(applicant1.errors["is_joint_tax_filing"].first).to include("Both spouses must have the same filing status if filing jointly")
      end

      it "applicant must answer is being claimed as a tax dependent" do
        applicant1.send(:presence_of_attr_step_1)
        expect(applicant1.errors["is_claimed_as_tax_dependent"].first).to include("is_claimed_as_tax_dependent can't be blank")
      end

      it "applicant must specifiy who is claiming them if they are being claimed as a tax dependent" do
        allow(applicant1).to receive(:is_claimed_as_tax_dependent).and_return(true)
        applicant1.send(:presence_of_attr_step_1)
        expect(applicant1.errors["claimed_as_tax_dependent_by"].first).to include("This person will be claimed as a dependent by' can't be blank")
      end

      it "applicant must answer if they are required to file taxes" do
        allow(applicant1).to receive(:is_required_to_file_taxes).and_return(nil)
        applicant1.send(:presence_of_attr_step_1)
        expect(applicant1.errors["is_claimed_as_tax_dependent"].first).to include("is_claimed_as_tax_dependent can't be blank")
      end
    end
  end
end

