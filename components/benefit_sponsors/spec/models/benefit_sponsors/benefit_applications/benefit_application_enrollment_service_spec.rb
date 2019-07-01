require 'rails_helper'

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationEnrollmentService, type: :model, :dbclean => :after_each do
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }

    let(:market_inception) { TimeKeeper.date_of_record.year }
    let(:current_effective_date) { Date.new(market_inception, 8, 1) }

    include_context "setup benefit market with market catalogs and product packages"

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    describe '.renew' do
      let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
      let(:aasm_state) { :active }
      let(:business_policy) { instance_double("some_policy", success_results: "validated successfully")}
      include_context "setup initial benefit application"

      before(:each) do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 6, 10))
      end

      after(:each) do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

      context "when initial employer eligible for renewal" do

        it "should generate renewal application" do
          allow(subject).to receive(:business_policy).and_return(business_policy)
          allow(business_policy).to receive(:is_satisfied?).with(initial_application).and_return(true)
          subject.renew_application
          benefit_sponsorship.reload

          renewal_application = benefit_sponsorship.benefit_applications.detect{|application| application.is_renewing?}
          expect(renewal_application).not_to be_nil

          expect(renewal_application.start_on.to_date).to eq current_effective_date.next_year
          expect(renewal_application.benefit_sponsor_catalog).not_to be_nil
          expect(renewal_application.benefit_packages.count).to eq 1
        end
      end
    end

    describe '.revert_application' do
    end

    describe '.submit_application' do
      let(:market_inception) { TimeKeeper.date_of_record.year - 1 }

      context "when initial employer present with valid application" do

        let(:open_enrollment_begin) { Date.new(TimeKeeper.date_of_record.year, 7, 3) }

        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
          let(:open_enrollment_period) { open_enrollment_begin..(effective_period.min - 10.days) }
          let(:aasm_state) { :draft }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 7, 4))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "open enrollment start date in the past" do

          context "and the benefit_application passes business policy validation" do

            it "should submit application with immediate open enrollment" do
              subject.submit_application
              initial_application.reload
              expect(initial_application.aasm_state).to eq :enrollment_open
              expect(initial_application.open_enrollment_period.begin.to_date).to eq TimeKeeper.date_of_record
            end
          end

          context "and the benefit_application fails business policy validation" do
            let(:business_policy) { instance_double("some_policy", fail_results: { business_rule: "failed validation" })}

            it "application should transition into :draft state" do
              allow(subject).to receive(:business_policy).and_return(business_policy)
              allow(subject).to receive(:business_policy_satisfied_for?).with(:submit_benefit_application).and_return(false)

              subject.submit_application
              initial_application.reload
              expect(initial_application.aasm_state).to eq :draft
            end
          end

        end

        context "open enrollment start date in the future" do
          let(:open_enrollment_begin) { Date.new(TimeKeeper.date_of_record.year, 7, 5) }

          it "should submit application with approved status" do
            subject.submit_application
            initial_application.reload
            expect(initial_application.aasm_state).to eq :approved
          end
        end
      end

      context "when renewing employer present with renewal application" do

      end
    end

    describe '.force_submit_application' do

      context 'initial employer' do
        include_context "setup initial benefit application"
        let(:current_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context 'when business policy satisfied and application is eligible' do

          before do
            allow(subject).to receive(:business_policy_satisfied_for?).with(:force_submit_benefit_application).and_return(true)
            allow(subject).to receive(:is_application_eligible?).and_return(true)
          end

          context 'and before open enrollment begin date' do

            before(:each) do
              TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period.min - 2.days)
            end

            after(:each) do
              TimeKeeper.set_date_of_record_unprotected!(Date.today)
            end

            context 'and application in draft state' do
              let(:aasm_state) { :draft }

              it 'should approve' do
                subject.force_submit_application
                initial_application.reload
                expect(subject.messages).to eq({})
                expect(subject.errors).to eq(['Employer(s) Plan Year date has not matched.'])
                expect(initial_application.aasm_state).to eq :approved
              end
            end

            context 'and application in exception states' do
              let(:aasm_state) { :pending }

              it 'should approve' do
                subject.force_submit_application
                initial_application.reload
                expect(subject.messages).to eq({})
                expect(subject.errors).to eq(['Employer(s) Plan Year date has not matched.'])
                expect(initial_application.aasm_state).to eq :approved
              end
            end

            context 'and application in submitted state' do
              let(:aasm_state) { :enrollment_open }

              it 'should fail' do
                subject.force_submit_application
                initial_application.reload
                expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed.')
                expect(subject.errors).to eq([])
                expect(initial_application.aasm_state).to eq :enrollment_open
              end
            end
          end

          context 'after open enrollment begin date' do

            before(:each) do
              TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period.min + 2.days)
            end

            after(:each) do
              TimeKeeper.set_date_of_record_unprotected!(Date.today)
            end

            context 'and application in draft state' do
              let(:aasm_state) { :draft }

              it 'should apporove and begin open enrollment' do
                subject.force_submit_application
                initial_application.reload
                expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully published.')
                expect(subject.errors).to eq([])
                expect(initial_application.aasm_state).to eq :enrollment_open
              end
            end

            context 'and application in exception states' do
              let(:aasm_state) { :pending }

              it 'should apporove and begin open enrollment' do
                subject.force_submit_application
                initial_application.reload
                expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully published.')
                expect(subject.errors).to eq([])
                expect(initial_application.aasm_state).to eq :enrollment_open
              end
            end

            context 'and application in submitted state' do
              let(:aasm_state) { :enrollment_open }

              it 'should fail' do
                subject.force_submit_application
                initial_application.reload
                expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed.')
                expect(subject.errors).to eq([])
                expect(initial_application.aasm_state).to eq :enrollment_open
              end
            end
          end
        end

        context 'when business policy not satisfied' do

          let(:business_policy)    { double(fail_results: {}) }

          before do
            allow(subject).to receive(:business_policy_satisfied_for?).with(:force_submit_benefit_application).and_return(false)
            allow(subject).to receive(:is_application_eligible?).and_return(true)
            allow(subject).to receive(:business_policy).and_return(business_policy)
            TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period.min + 2.days)
          end

          after(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.today)
          end

          context 'and application in draft state' do
            let(:aasm_state) { :draft }

            it 'should be submitted for review' do
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully submitted for review.')
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :pending
            end
          end

          context 'and application in exception states' do
            let(:aasm_state) { :pending }

            it 'should fail with notice' do
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed.')
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :pending
            end
          end

          context 'and application in submitted state' do
            let(:aasm_state) { :enrollment_open }

            it 'should fail with notice' do
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed.')
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :enrollment_open
            end
          end
        end
      end

      context 'renewing employer' do
        include_context "setup renewal application"

        let(:renewal_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
        let(:current_effective_date) { renewal_effective_date.prev_year }

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(renewal_application) }

        context 'when business policy satisfied and application is eligible' do

          before do
            allow(subject).to receive(:business_policy_satisfied_for?).with(:force_submit_benefit_application).and_return(true)
            allow(subject).to receive(:is_application_eligible?).and_return(true)
          end

          context 'and before open enrollment begin date' do

            before(:each) do
              TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period.min - 2.days)
            end

            after(:each) do
              TimeKeeper.set_date_of_record_unprotected!(Date.today)
            end

            context 'and application in draft state' do
              let(:renewal_state) { :draft }

              it 'should approve' do
                subject.force_submit_application
                renewal_application.reload
                expect(subject.messages).to eq({})
                expect(subject.errors).to eq(['Employer(s) Plan Year date has not matched.'])
                expect(renewal_application.aasm_state).to eq :approved
              end
            end

            context 'and application in exception states' do
              let(:renewal_state) { :pending }

              it 'should approve' do
                subject.force_submit_application
                renewal_application.reload
                expect(subject.messages).to eq({})
                expect(subject.errors).to eq(['Employer(s) Plan Year date has not matched.'])
                expect(renewal_application.aasm_state).to eq :approved
              end
            end

            context 'and application in submitted state' do
              let(:renewal_state) { :enrollment_open }

              it 'should fail' do
                subject.force_submit_application
                renewal_application.reload
                expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed.')
                expect(subject.errors).to eq([])
                expect(renewal_application.aasm_state).to eq :enrollment_open
              end
            end
          end

          context 'after open enrollment begin date' do

            before(:each) do
              TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period.min + 2.days)
            end

            after(:each) do
              TimeKeeper.set_date_of_record_unprotected!(Date.today)
            end

            context 'and application in draft state' do
              let(:renewal_state) { :draft }

              it 'should apporove and begin open enrollment' do
                subject.force_submit_application
                renewal_application.reload
                expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully published.')
                expect(subject.errors).to eq([])
                expect(renewal_application.aasm_state).to eq :enrollment_open
              end
            end

            context 'and application in exception states' do
              let(:renewal_state) { :pending }

              it 'should apporove and begin open enrollment' do
                subject.force_submit_application
                renewal_application.reload
                expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully published.')
                expect(subject.errors).to eq([])
                expect(renewal_application.aasm_state).to eq :enrollment_open
              end
            end

            context 'and application in submitted state' do
              let(:renewal_state) { :enrollment_open }

              it 'should fail' do
                subject.force_submit_application
                renewal_application.reload
                expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed.')
                expect(subject.errors).to eq([])
                expect(renewal_application.aasm_state).to eq :enrollment_open
              end
            end
          end
        end

        context 'when business policy not satisfied' do

          let(:business_policy)    { double(fail_results: {}) }

          before do
            allow(subject).to receive(:business_policy_satisfied_for?).with(:force_submit_benefit_application).and_return(false)
            allow(subject).to receive(:is_application_eligible?).and_return(true)
            allow(subject).to receive(:business_policy).and_return(business_policy)
            TimeKeeper.set_date_of_record_unprotected!(open_enrollment_period.min + 2.days)
          end

          after(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.today)
          end

          context 'and application in draft state' do
            let(:renewal_state) { :draft }

            it 'should be submitted for review' do
              subject.force_submit_application
              renewal_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully submitted for review.')
              expect(subject.errors).to eq([])
              expect(renewal_application.aasm_state).to eq :pending
            end
          end

          context 'and application in exception states' do
            let(:renewal_state) { :pending }

            it 'should fail with notice' do
              subject.force_submit_application
              renewal_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed.')
              expect(subject.errors).to eq([])
              expect(renewal_application.aasm_state).to eq :pending
            end
          end

          context 'and application in submitted state' do
            let(:renewal_state) { :enrollment_open }

            it 'should fail with notice' do
              subject.force_submit_application
              renewal_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed.')
              expect(subject.errors).to eq([])
              expect(renewal_application.aasm_state).to eq :enrollment_open
            end
          end
        end
      end

      context "today is date for force publish", dbclean: :after_each do
        let(:open_enrollment_begin) { Date.new(TimeKeeper.date_of_record.year, 7, 3) }

        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
          let(:open_enrollment_period) { open_enrollment_begin..(effective_period.min - 10.days) }
          let(:aasm_state) { :draft }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 7, 4))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        it "should transition the benefit_application into :enrollment_open" do
          subject.submit_application
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_open
        end

        context "the active benefit_application has benefits that can be mapped into renewal benefit_application" do
          it "should autorenew all active members"
        end

        context "the active benefit_application has benefits that Cannot be mapped into renewal benefit_application" do
          it "should not autorenew all active members"
        end
      end
    end

    describe '.begin_open_enrollment' do
      context "when initial employer present with valid approved application" do

        let(:open_enrollment_begin) { TimeKeeper.date_of_record - 5.days }

        include_context "setup initial benefit application" do
          let(:aasm_state) { :approved }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 6, 10))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "open enrollment start date in the past" do

          it "should begin open enrollment" do
            subject.begin_open_enrollment
            initial_application.reload
            expect(initial_application.aasm_state).to eq :enrollment_open
          end
        end

        context "open enrollment start date in the future" do
          let(:open_enrollment_begin) { TimeKeeper.date_of_record + 5.days }

          it "should do nothing" do
            expect(initial_application.aasm_state).to eq :approved
          end
        end
      end

      context "when renewing employer present with renewal application" do

      end
    end

    describe '.end_open_enrollment' do
      context "when initial employer successfully completed enrollment period" do

        let(:open_enrollment_close) { TimeKeeper.date_of_record.prev_day }
        let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
        let(:aasm_state) { :enrollment_open }
        let(:open_enrollment_period) { effective_period.min.prev_month..open_enrollment_close }

        include_context "setup initial benefit application" do
          let(:aasm_state) { :enrollment_open }
          let(:benefit_sponsorship_state) { :applicant }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 7, 24))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "open enrollment close date passed" do
          before :each do
            initial_application.benefit_sponsorship.update_attributes(aasm_state: :applicant)
            allow(::BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator).to receive(:call).with(initial_application, Date.new(Date.today.year, 7, 24))
          end

          context "and the benefit_application enrollment passes eligibility policy validation" do
            let(:business_policy) { instance_double("some_policy", success_results: { business_rule: "validation passed" })}
            before do
              allow(subject).to receive(:business_policy).and_return(business_policy)
              allow(subject).to receive(:business_policy_satisfied_for?).with(:end_open_enrollment).and_return(true)
            end
            it "should close open enrollment" do
              subject.end_open_enrollment
              initial_application.reload
              expect(initial_application.aasm_state).to eq :enrollment_closed
            end
          end

          context "and the benefit_application enrollment fails eligibility policy validation" do
            let(:business_policy) { instance_double("some_policy", fail_results: { business_rule: "failed validation" })}

            it "should close open enrollment and transition into :enrollment_ineligible state" do
              allow(subject).to receive(:business_policy).and_return(business_policy)
              allow(subject).to receive(:business_policy_satisfied_for?).with(:end_open_enrollment).and_return(false)

              subject.end_open_enrollment
              initial_application.reload
              expect(initial_application.aasm_state).to eq :enrollment_ineligible
              expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
            end
          end


          it "invokes pricing determination calculation" do
            expect{::BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator.call(initial_application, Date.new(Date.today.year, 7, 24))}.not_to raise_error
            subject.end_open_enrollment
          end
        end

        context "open enrollment close date in the future" do
          let(:open_enrollment_close) { TimeKeeper.date_of_record.next_day }

          it "should do nothing" do
            subject.begin_open_enrollment
            initial_application.reload
            expect(initial_application.aasm_state).to eq :enrollment_open
          end
        end
      end

      context "when renewing employer present with renewal application" do
      end

      context "when employer open enrollment extended" do

        let(:open_enrollment_close) { TimeKeeper.date_of_record + 2.days }
        let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }        
        let(:benefit_sponsorship_state) { :applicant }

        include_context "setup initial benefit application" do
          let(:aasm_state) { :enrollment_extended }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 7, 24))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "open enrollment close invoked with earlier date" do
          let(:business_policy) { instance_double("some_policy", success_results: { business_rule: "validation passed" })}

          before do
            initial_application.update(open_enrollment_period: effective_period.min.prev_month..open_enrollment_close)
            initial_application.benefit_sponsorship.update(aasm_state: benefit_sponsorship_state)
            allow(subject).to receive(:business_policy).and_return(business_policy)
            allow(subject).to receive(:business_policy_satisfied_for?).with(:end_open_enrollment).and_return(true)
            allow(BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator).to receive(:enrollment_and_waiver_count_for).and_return([1, 1])
            allow(BenefitSponsors::SponsoredBenefits::EnrollmentClosePricingDeterminationCalculator).to receive(:enrollment_id_list_for).and_return([])
          end

          # it "should close open enrollment and reset OE end date" do
          #   expect(initial_application.open_enrollment_period.max).to eq open_enrollment_close
          #   subject.end_open_enrollment(TimeKeeper.date_of_record)
          #   initial_application.reload
          #   expect(initial_application.open_enrollment_period.max).to eq TimeKeeper.date_of_record
          #   expect(initial_application.aasm_state).to eq :enrollment_closed
          # end
        end
      end
    end

    describe '.begin_benefit' do

      context "when initial employer completed open enrollment and ready to begin benefit" do

        let(:application_state) { :enrollment_closed }

        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year, 8, 1) }
          let(:aasm_state) {  application_state }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 7, 24))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "made binder payment" do
          let(:application_state) { :enrollment_eligible }

          before do
            allow(initial_application).to receive(:transition_benefit_package_members).and_return(true)
          end

          it "should begin benefit" do
            subject.begin_benefit
            initial_application.reload
            expect(initial_application.aasm_state).to eq :active
          end
        end

        context "binder not paid" do

          let(:aasm_state) {  :canceled } # benefit application will be moved to canceled state when binder payment is missed.

          it "should raise an exception" do
            expect{subject.begin_benefit}.to raise_error(StandardError)
          end
        end
      end

      context "when renewing employer present with renewal application" do

      end
    end

    describe '.end_benefit' do
      context "when employer application exists with active application" do

        let(:market_inception) { TimeKeeper.date_of_record.year - 1 }


        include_context "setup initial benefit application" do
          let(:current_effective_date) { Date.new(TimeKeeper.date_of_record.year - 1, 8, 1) }
          let(:aasm_state) { :active }
        end

        before(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 8, 1))
        end

        after(:each) do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context "when end date is in past" do

          before do
            allow(initial_application).to receive(:transition_benefit_package_members).and_return(true)
          end

          it "should close benefit" do
            subject.end_benefit
            initial_application.reload
            expect(initial_application.aasm_state).to eq :expired
          end
        end
      end
    end

    describe '.cancel' do

      include_context "setup initial benefit application"

      subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

      context "when a benefit application is canceled" do
        before do
          subject.cancel
          initial_application.reload
        end

        it "should move benefit application to canceled" do
          expect(initial_application.aasm_state).to eq :canceled
        end

        it "should update end date on benefit application" do
          # expect(initial_application.end_on).to eq initial_application.start_on
        end
      end

      context 'when an approved/published benefit application is canceled' do

        before do
          initial_application.update_attributes(aasm_state: :approved)
          subject.cancel
          initial_application.reload
        end

        it "should move benefit_application to canceled state" do
          expect(initial_application.aasm_state).to eq :canceled
        end
      end
    end

    describe '.schedule_termination' do
      context "when an employer is scheduled for termination" do
        include_context "setup initial benefit application"
        let(:end_date) { TimeKeeper.date_of_record.next_month.end_of_month }

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        before do
          subject.schedule_termination(end_date, TimeKeeper.date_of_record, "voluntary", "Company went out of business/bankrupt", false)
          initial_application.reload
        end

        it "should move benefit application to termiantion pending" do
          expect(initial_application.aasm_state).to eq :termination_pending
        end

        it "should update end date on benefit application" do
          expect(initial_application.end_on).to eq end_date
        end

        it "should update the termination kind" do
          expect(initial_application.termination_kind).to eq "voluntary"
        end

        it "should update the termination reason" do
          expect(initial_application.termination_reason).to eq "Company went out of business/bankrupt"
        end
      end
    end

    describe '.terminate' do
      context "when an employer is terminated" do
        include_context "setup initial benefit application"
        let(:date)  { TimeKeeper.date_of_record }
        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context 'with other than end of the month date' do
          let(:end_date) { Date.new(date.year, date.month, 12) }

          before do
            subject.terminate(end_date, TimeKeeper.date_of_record, "voluntary", "Company went out of business/bankrupt", false)
            initial_application.reload
          end

          it "should NOT terminate benefit application" do
            expect(initial_application.aasm_state).to eq :active
          end

          it "should NOT update benefit application end date" do
            expect(initial_application.end_on).not_to eq end_date
          end
        end

        context 'with other than end of the month date' do
          let(:end_date) { Date.new(date.year, date.month, 12) }

          it "should return errors" do
            result, benefit_application, errors = subject.terminate(end_date, TimeKeeper.date_of_record, "voluntary", "Company went out of business/bankrupt", false)
            expect(errors.keys.include?(:mid_month_voluntary_term)).to be_truthy
            expect(result).to be_falsey
            expect(benefit_application.aasm_state).to eq :active
          end
        end

        context 'with end of the month date' do
          let(:end_date) { date.end_of_month }

          before do
            subject.terminate(end_date, TimeKeeper.date_of_record, "voluntary", "Company went out of business/bankrupt", false)
            initial_application.reload
          end

          it "should terminate benefit application" do
            expect(initial_application.aasm_state).to eq :terminated
          end

          it "should update benefit application end date" do
            expect(initial_application.end_on).to eq end_date
          end
        end
      end

    end

    describe '.reinstate' do
    end

    describe '.extend_open_enrollment' do
      include_context "setup initial benefit application"
      let(:current_effective_date) { Date.new(Date.today.year, 8, 1) }
      let(:today) { current_effective_date - 7.days }

      subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

      before(:each) do
        TimeKeeper.set_date_of_record_unprotected!(today)
      end

      after(:each) do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      context 'when application is ineligible' do 
        let(:aasm_state) { :enrollment_ineligible }
        let(:benefit_sponsorship_state) { :applicant }
        let(:today) { current_effective_date - 7.days }
        let(:oe_end_date) { current_effective_date - 5.days }

        it 'should extend open enrollment' do 
          expect(initial_application.aasm_state).to eq :enrollment_ineligible
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          subject.extend_open_enrollment(oe_end_date)
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_extended
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          expect(initial_application.open_enrollment_period.max).to eq oe_end_date
        end
      end

      context 'when application canceled due to ineligibility' do
        let(:aasm_state) { :canceled }
        let(:benefit_sponsorship_state) { :applicant }
        let(:today) { current_effective_date + 2.days }
        let(:oe_end_date) { current_effective_date + 5.days }

        it 'should extend open enrollment' do 
          expect(initial_application.aasm_state).to eq :canceled
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          subject.extend_open_enrollment(oe_end_date)
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_extended
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          expect(initial_application.open_enrollment_period.max).to eq oe_end_date
        end
      end

      context 'when application open enrollment closed' do
        let(:aasm_state) { :enrollment_closed }
        let(:benefit_sponsorship_state) { :applicant }
        let(:today) { current_effective_date - 8.days }
        let(:oe_end_date) { current_effective_date - 5.days }

        it 'should extend open enrollment' do 
          expect(initial_application.aasm_state).to eq :enrollment_closed
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          subject.extend_open_enrollment(oe_end_date)
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_extended
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          expect(initial_application.open_enrollment_period.max).to eq oe_end_date
        end
      end

      context 'when application open enrollment open' do
        let(:aasm_state) { :enrollment_open }
        let(:benefit_sponsorship_state) { :applicant }
        let(:today) { current_effective_date - 13.days }
        let(:oe_end_date) { current_effective_date - 5.days }

        it 'should extend open enrollment' do 
          expect(initial_application.aasm_state).to eq :enrollment_open
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          subject.extend_open_enrollment(oe_end_date)
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_extended
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          expect(initial_application.open_enrollment_period.max).to eq oe_end_date
        end
      end
    end

    describe '.hbx_enrollments_by_month' do

      include_context "setup initial benefit application"
      let(:product_kinds)  { [:health, :dental] }
      let(:dental_sponsored_benefit) { true }
      let(:health_sb) { current_bp.sponsored_benefit_for(:health) }
      let(:dental_sb) { current_bp.sponsored_benefit_for(:dental) }
      let(:benefit_package) { initial_application.benefit_packages.first }
      let(:benefit_group_assignment) {FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package)}
      let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id) }
      let(:census_employee) { FactoryBot.create(:census_employee,
        employer_profile: benefit_sponsorship.profile,
        benefit_sponsorship: benefit_sponsorship,
        benefit_group_assignments: [benefit_group_assignment]
      )}
      let(:person){ FactoryBot.create(:person, :with_family)}
      let(:family) {person.primary_family}

      let!(:hbx_enrollment) {  FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        family: family,
                        household: family.active_household,
                        aasm_state: "coverage_selected",
                        effective_on: initial_application.start_on,
                        rating_area_id: initial_application.recorded_rating_area_id,
                        coverage_kind: "health",
                        sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id:initial_application.benefit_packages.first.id,
                        benefit_sponsorship_id:initial_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id)
      }

      let!(:dental_hbx_enrollment) {  FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        family: family,
                        household: family.active_household,
                        aasm_state: "coverage_selected",
                        effective_on: initial_application.start_on,
                        rating_area_id: initial_application.recorded_rating_area_id,
                        coverage_kind: "dental",
                        sponsored_benefit_id: initial_application.benefit_packages.first.dental_sponsored_benefit.id,
                        sponsored_benefit_package_id:initial_application.benefit_packages.first.id,
                        benefit_sponsorship_id:initial_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id)
      }

      let!(:enrollment_service) { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }
      let!(:enrollments) { enrollment_service.hbx_enrollments_by_month(initial_application.start_on) }

      it 'should return enrollments - both health and dental' do
        expect(enrollments.map{ |k| k["coverage_kind"] }).to eq ['health', 'dental']
      end
    end
  end
end
