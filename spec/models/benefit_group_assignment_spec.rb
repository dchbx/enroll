require 'rails_helper'

describe BenefitGroupAssignment, type: :model do
  it { should validate_presence_of :benefit_group_id }
  it { should validate_presence_of :start_on }
  it { should validate_presence_of :is_active }

  let(:benefit_group)     { FactoryGirl.create(:benefit_group)  }
  let(:employer_profile)  { benefit_group.plan_year.employer_profile }
  let(:census_employee)   { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:start_on)          { benefit_group.plan_year.start_on }

  describe ".new" do
    let(:valid_params) do
      {
        census_employee: census_employee,
        benefit_group: benefit_group,
        start_on: start_on
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(BenefitGroupAssignment.create(**params).save).to be_falsey
      end
    end

    context "with no start on date" do
      let(:params) {valid_params.except(:start_on)}

      it "should be invalid" do
        expect(BenefitGroupAssignment.create(**params).errors[:start_on].any?).to be_truthy
      end
    end

    context "with no benefit group" do
      let(:params) {valid_params.except(:benefit_group)}

      it "should be invalid" do
        expect(BenefitGroupAssignment.create(**params).errors[:benefit_group_id].any?).to be_truthy
      end
    end

    context "with no census employee" do
      let(:params) {valid_params.except(:census_employee)}

      it "should raise" do
        expect{BenefitGroupAssignment.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "and invalid dates are specified" do
      let(:params) {valid_params}
      let(:benefit_group_assignment)  { BenefitGroupAssignment.new(**params) }

      context "start too early" do
        before { benefit_group_assignment.start_on = benefit_group.plan_year.start_on - 1.day }

        it "should be invalid" do
          expect(benefit_group_assignment.valid?).to be_falsey
          expect(benefit_group_assignment.errors[:start_on].any?).to be_truthy
          expect(benefit_group_assignment.errors.messages[:start_on].first).to match(/can't occur outside plan year dates/)
        end
      end

      context "start too late" do
        before { benefit_group_assignment.start_on = benefit_group.plan_year.end_on + 1.day }

        it "should be invalid" do
          expect(benefit_group_assignment.valid?).to be_falsey
          expect(benefit_group_assignment.errors[:start_on].any?).to be_truthy
          expect(benefit_group_assignment.errors.messages[:start_on].first).to match(/can't occur outside plan year dates/)
        end
      end

      context "end too early" do
        before { benefit_group_assignment.end_on = benefit_group.plan_year.start_on - 1.day }

        it "should be invalid" do
          expect(benefit_group_assignment.valid?).to be_falsey
          expect(benefit_group_assignment.errors[:end_on].any?).to be_truthy
          expect(benefit_group_assignment.errors.messages[:end_on].first).to match(/can't occur outside plan year dates/)
        end
      end

      context "end too late" do
        before { benefit_group_assignment.end_on = benefit_group.plan_year.end_on + 1.day }

        it "should be invalid" do
          expect(benefit_group_assignment.valid?).to be_falsey
          expect(benefit_group_assignment.errors[:end_on].any?).to be_truthy
          expect(benefit_group_assignment.errors.messages[:end_on].first).to match(/can't occur outside plan year dates/)
        end
      end
    end

    context "and valid dates are specified" do
      let(:params) {valid_params}
      let(:benefit_group_assignment)  { BenefitGroupAssignment.new(**params) }

      context "start and end timely" do
        before do
          benefit_group_assignment.start_on = benefit_group.plan_year.start_on
          benefit_group_assignment.end_on   = benefit_group.plan_year.end_on
        end

        it "should be valid" do
          expect(benefit_group_assignment.valid?).to be_truthy
        end
      end
    end

    context "with all valid parameters" do
      let(:params) {valid_params}
      let(:benefit_group_assignment)  { BenefitGroupAssignment.new(**params) }

      it "should save" do
        expect(benefit_group_assignment.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_benefit_group_assignment) do
          b = BenefitGroupAssignment.new(**params)
          b.save!
          b
        end

        it "should be findable" do
          expect(BenefitGroupAssignment.find(saved_benefit_group_assignment._id)._id).to eq saved_benefit_group_assignment.id
        end
      end

      context "and benefit coverage activity occurs" do
        it "should start in initialized state" do
          expect(benefit_group_assignment.initialized?).to be_truthy
        end

        context "and employee is terminated before selecting or waiving coverage" do
          before { benefit_group_assignment.terminate_coverage }

          it "should transition to coverage void status" do
            expect(benefit_group_assignment.aasm_state).to eq "coverage_void"
          end
        end

        context "and coverage is selected" do
          before { benefit_group_assignment.select_coverage }

          it "should transistion to coverage selected state" do
            expect(benefit_group_assignment.coverage_selected?).to be_truthy
          end

          context "without an associated hbx_enrollment" do
            it "should be invalid" do
              expect(benefit_group_assignment.valid?).to be_falsey
              expect(benefit_group_assignment.errors[:hbx_enrollment].any?).to be_truthy
            end
          end

          context "with an associated, matching hbx_enrollment" do
            let(:employee_role)   { FactoryGirl.build(:employee_role, employer_profile: employer_profile )}
            let(:hbx_enrollment)  { HbxEnrollment.new(benefit_group: benefit_group, employee_role: census_employee.employee_role ) }

            before { benefit_group_assignment.hbx_enrollment = hbx_enrollment }

            it "should be valid" do
              expect(benefit_group_assignment.valid?).to be_truthy
            end

            context "and hbx_enrollment is non-matching" do
              let(:other_benefit_group)     { FactoryGirl.build(:benefit_group) }
              let(:other_plan_year)         { FactoryGirl.build(:plan_year, benefit_group: benefit_group) }
              let(:other_employer_profile)  { FactoryGirl.create(:employer_profile, plan_year: plan_year) }
              let(:other_employee_role)     { FactoryGirl.create(:employee_role, employer_profile: employer_profile) }

              context "because it has different benefit group" do
                before { hbx_enrollment.benefit_group = other_benefit_group }

                it "should be invalid" do
                  expect(benefit_group_assignment.valid?).to be_falsey
                  expect(benefit_group_assignment.errors[:hbx_enrollment].any?).to be_truthy
                end
              end
           
              # context "because it has different employee role" do
              #   before { hbx_enrollment.employee_role = other_benefit_group }

              #   it "should be invalid" do
              #     allow(census_employee).to receive(:employee_role_linked?).and_return(true)
              #     expect(benefit_group_assignment.valid?).to be_falsey
              #     expect(benefit_group_assignment.errors[:hbx_enrollment].any?).to be_truthy
              #   end
              # end
            end
          end
        end

        context "and coverage is waived" do
          before { benefit_group_assignment.waive_coverage }

          it "should transistion to coverage waived state" do
            expect(benefit_group_assignment.coverage_waived?).to be_truthy
          end

          context "and waived coverage is terminated" do

            it "should fail transition and remain in coverage waived state" do
              expect { benefit_group_assignment.terminate_coverage! }.to raise_error AASM::InvalidTransition
              expect(benefit_group_assignment.coverage_waived?).to be_truthy
            end
          end

          context "and the employee reconsiders and selects coverage" do
            before { benefit_group_assignment.select_coverage }

            it "should transistion back to coverage selcted state" do
              expect(benefit_group_assignment.coverage_selected?).to be_truthy
            end

            context "and coverage is terminated" do
              before { benefit_group_assignment.terminate_coverage }

              it "should transistion to coverage terminated state" do
                expect(benefit_group_assignment.coverage_terminated?).to be_truthy
              end
            end
          end
        end

        context "and coverage is terminated" do
          before { benefit_group_assignment.terminate_coverage }

          it "should transistion to coverage coverage_unused state" do
            expect(benefit_group_assignment.coverage_void?).to be_truthy
          end

        end
      end
    end
  end

  describe "#deactivate_benefitgroup_assignment" do
    let(:valid_params) do
      {
          census_employee: census_employee,
          benefit_group: benefit_group,
          start_on: start_on,
          aasm_state: "coverage_selected"
      }
    end
    let(:params) {valid_params}
    let(:benefit_group_assignment)  { BenefitGroupAssignment.new(**params) }

    it "deactivates active benefit group assignment" do
      benefit_group_assignment.terminate_coverage!
      expect(benefit_group_assignment.aasm_state).to eq "coverage_terminated"
      expect(benefit_group_assignment.is_active).to eq(false)
      expect(benefit_group_assignment.end_on).to eq benefit_group.end_on
    end
  end

  describe '#active_and_waived_enrollments', dbclean: :after_each do

    let(:household) { FactoryGirl.create(:household, family: family)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}

    shared_examples_for "active and waived enrollments" do |state, status, result|

      let!(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: household,
                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id, 
                          aasm_state: state
                          )}

      it "should #{status}return the #{state} enrollments" do
        result = (result == "active_enrollment") ?  [enrollment] : result
        expect(census_employee.active_benefit_group_assignment.active_and_waived_enrollments).to eq result
      end
    end

    it_behaves_like "active and waived enrollments", "coverage_terminated", "not ", []
    it_behaves_like "active and waived enrollments", "coverage_expired", "not ", []
    it_behaves_like "active and waived enrollments", "coverage_selected", "", "active_enrollment"
    it_behaves_like "active and waived enrollments", "inactive", "", "active_enrollment"
  end
end
