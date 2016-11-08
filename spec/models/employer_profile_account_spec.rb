require 'rails_helper'

describe EmployerProfileAccount, type: :model, dbclean: :after_each do

  let(:employer_profile)        { FactoryGirl.create(:employer_profile) }
  def persisted_employer_profile
    EmployerProfile.find(employer_profile.id)
  end

  let(:open_enrollment_start_on)    { TimeKeeper.date_of_record }
  let(:open_enrollment_end_on)      { open_enrollment_start_on + Settings.aca.shop_market.open_enrollment.minimum_length.days - 1.day }
  let(:start_on)                    { open_enrollment_start_on + 1.month }
  let(:end_on)                      { start_on + 1.year - 1.day }

  let(:binder_payment_due_on)   { open_enrollment_end_on + 2.days }
  let(:next_premium_due_on)     { binder_payment_due_on }
  let(:next_premium_amount)     { 3155.86 }

  let(:valid_params) do
    {
      employer_profile: employer_profile,
      next_premium_due_on: next_premium_due_on,
      next_premium_amount: next_premium_amount
    }
  end

  before do
    TimeKeeper.set_date_of_record_unprotected!(Date.current.next_month.beginning_of_month)
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context ".new" do
    context "with no employer profile" do
      let(:params) {valid_params.except(:employer_profile)}

      it "should raise" do
        expect{EmployerProfileAccount.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no next_premium_due_on" do
      let(:params) {valid_params.except(:next_premium_due_on)}

      it "should fail validation" do
        expect(EmployerProfileAccount.create(**params).errors[:next_premium_due_on].any?).to be_truthy
      end
    end

    context "with no next_premium_amount" do
      let(:params) {valid_params.except(:next_premium_amount)}

      it "should fail validation" do
        expect(EmployerProfileAccount.create(**params).errors[:next_premium_amount].any?).to be_truthy
      end
    end

    context "with all valid parameters" do
      let(:params) { valid_params }
      let(:employer_profile_account)  { EmployerProfileAccount.new(**params) }

      it "should initialize with premium binder pending state" do
        expect(employer_profile_account.binder_pending?).to be_truthy
      end

      it "should enable valid state transitions" do
        expect(employer_profile_account.may_allocate_binder_payment?).to be_truthy
        expect(employer_profile_account.may_advance_billing_period?).to be_truthy
      end

      it "should not enable invalid state transistions" do
        expect(employer_profile_account.may_reverse_coverage_period?).to be_falsey
      end

      it "should save" do
        expect(employer_profile_account.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_employer_profile_account) do
          acct = EmployerProfileAccount.new(**params)
          acct.save
          acct
        end

        it "should be findable" do
          expect(EmployerProfileAccount.find(saved_employer_profile_account.id)).to eq saved_employer_profile_account
        end

      end
    end

    context "and open enrollment has closed and is employer is eligible for coverage" do

      let(:benefit_group)             { FactoryGirl.create(:benefit_group) }
      let(:plan_year)                 { FactoryGirl.create(:plan_year,
                                          employer_profile: employer_profile,
                                          start_on: start_on,
                                          end_on: end_on,
                                          benefit_groups: [benefit_group],
                                          open_enrollment_start_on: open_enrollment_start_on,
                                          open_enrollment_end_on: open_enrollment_end_on
                                        ) }
      def persisted_plan_year
        PlanYear.find(plan_year.id)
      end

      let(:new_employer_profile_account) { persisted_employer_profile.employer_profile_account }

      def persisted_new_employer_profile_account
        EmployerProfileAccount.find(new_employer_profile_account.id)
      end

      let(:benefit_group_assignment)    { BenefitGroupAssignment.new(
                                            benefit_group: benefit_group,
                                            start_on: plan_year.start_on
                                          )}

      let(:census_employee)             { FactoryGirl.create(:census_employee,
                                            employer_profile: employer_profile,
                                            benefit_group_assignments: [benefit_group_assignment]
                                          ) }

      before do
        plan_year.publish!
        # allow_any_instance_of(CensusEmployee).to receive(:has_active_health_coverage?).and_return(true)
        allow(HbxEnrollment).to receive(:enrolled_shop_health_benefit_group_ids).with([census_employee.active_benefit_group_assignment.id]).and_return([census_employee.active_benefit_group_assignment.id])
        census_employee.active_benefit_group_assignment.select_coverage!

        TimeKeeper.set_date_of_record(open_enrollment_end_on + 1.day)
        new_employer_profile_account
      end

      it "employer profile and plan year should reflect enrollment is valid and complete" do
        expect(persisted_new_employer_profile_account.employer_profile.plan_years.first.aasm_state).to eq "enrolled"
        expect(persisted_new_employer_profile_account.employer_profile.aasm_state).to eq "eligible"
      end

      it "employer account should be waiting to receive binder payment" do
        expect(persisted_new_employer_profile_account.binder_pending?).to be_truthy
      end

      context "and employer pays the binder premium" do
        before do
          new_employer_profile_account.allocate_binder_payment!
        end

        it "should transition to binder paid status" do
          expect(persisted_new_employer_profile_account.binder_paid?).to be_truthy
        end

        it "and employer profile binder_credited event should fire" do
          expect(EmployerProfile.find(new_employer_profile_account.employer_profile.id).aasm_state).to eq "binder_paid"
        end

        context "and plan year hasn't started" do
          context "and binder premium payment is reversed" do
            before do
              new_employer_profile_account.reverse_coverage_period!
            end

            it "should revert to binder pending" do
              expect(persisted_new_employer_profile_account.aasm_state).to eq "binder_pending"
            end

            it "and it should revert employer profile back to eligible" do
              expect(persisted_new_employer_profile_account.employer_profile.aasm_state).to eq "eligible"
            end
          end
        end

        context "and plan year has started" do
          before do
            TimeKeeper.set_date_of_record(plan_year.start_on)
          end

          it "coverage should be in good standing" do
            expect(persisted_new_employer_profile_account.aasm_state).to eq "invoiced"
            expect(persisted_new_employer_profile_account.employer_profile.aasm_state).to eq "enrolled"
          end

          context "and binder premium payment is reversed" do
            before do
              new_employer_profile_account.reverse_coverage_period!
            end

            it "coverage should be canceled??"
            #   expect(persisted_new_employer_profile_account.aasm_state).to eq "canceled"
            #   expect(persisted_new_employer_profile_account.employer_profile.aasm_state).to eq "canceled"
            # end
          end

          context "they pay the invoice on the 5th" do
            before do
              TimeKeeper.set_date_of_record(TimeKeeper.date_of_record + 5.days)
              persisted_new_employer_profile_account.advance_coverage_period!
            end

            it "account should be current" do
              expect(persisted_new_employer_profile_account.aasm_state).to eq "current"
            end

            context "they miss their next payment" do
              before do
                TimeKeeper.set_date_of_record((TimeKeeper.date_of_record + 2.months).beginning_of_month)
              end

              it "should be past due" do
                expect(persisted_new_employer_profile_account.aasm_state).to eq "past_due"
              end

              context "and a second billing period advances without a premium payment" do
                before do
                  TimeKeeper.set_date_of_record(TimeKeeper.date_of_record + 1.month)
                end

                it "should transition to late status" do
                  expect(persisted_new_employer_profile_account.aasm_state).to eq "delinquent"
                end

                context "and a third billing period advances without a premium payment" do
                  before do
                    TimeKeeper.set_date_of_record(TimeKeeper.date_of_record + 1.month)
                  end

                  it "should transition to suspended status" do
                    expect(persisted_new_employer_profile_account.aasm_state).to eq "suspended"
                  end

                  it "should set parent employer to suspended" do
                    expect(persisted_new_employer_profile_account.employer_profile.aasm_state).to eq "suspended"
                  end

                  it "should transmit terminations notices to employer"
                  it "should transmit terminations notices to broker"
                  it "should transmit terminations notices to carrier"
                  it "should transmit terminations notices to employees"
                  it "should place employees in IVL SEPs??"

                  context "and a premium in arrears is paid-in-full" do
                    before do
                      persisted_new_employer_profile_account.advance_coverage_period!
                    end

                    it "should transition to current status" do
                      expect(persisted_new_employer_profile_account.aasm_state).to eq "current"
                    end

                    it "should set parent employer to enrolled"  do
                      expect(persisted_new_employer_profile_account.employer_profile.aasm_state).to eq "enrolled"
                    end

                    context "but the premium payment NSFs" do
                      before do
                        persisted_new_employer_profile_account.reverse_coverage_period
                      end

                      it "should revert to suspended status"

                      it "and reset employer to suspended status"
                    end
                  end

                  context "and a fourth (final) billing period advances without a premium payment" do
                    before do
                      TimeKeeper.set_date_of_record(TimeKeeper.date_of_record + 1.month)
                    end

                    it "should transition self to terminated status" do
                      expect(persisted_new_employer_profile_account.aasm_state).to eq "terminated"
                    end

                    it "should return the employer to applicant status" do
                      expect(persisted_employer_profile.aasm_state).to eq "applicant"
                    end
                  end
                end
              end
            end
          end
        end
      end

      context "and employer doesn't pay the premium binder before effective date" do
        before do
          TimeKeeper.set_date_of_record(plan_year.start_on)
          # new_employer_profile_account.advance_billing_period
        end

        it "coverage should be canceled" do
          expect(persisted_new_employer_profile_account.aasm_state).to eq "canceled"
        end

        it "employer should return to applicant status" do
          expect(persisted_new_employer_profile_account.employer_profile.aasm_state).to eq "applicant"
        end
      end

    end
  end
end
