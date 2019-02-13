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
      include_context "setup initial benefit application"

      context 'Invoke force_submit_application' do
        let(:application_errors) do
          { 'invalid_application' => 'Invalid application error' }
        end
        let(:application_warnings) do
          { 'invalid_application' => 'Invalid application warning' }
        end
        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

        context 'When business_policy_satisfied_for? OR is_application_eligible? AND may_submit_for_review? are is false' do

          it 'should return notice, warnings and state could not be changed' do
            allow(initial_application).to receive(:open_enrollment_length).and_return(4)
            allow(initial_application).to receive(:may_submit_for_review?).and_return(false)
            subject.force_submit_application
            initial_application.reload
            expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed')
            expect(subject.messages['warnings']).to eq(['open enrollment period length 4 day(s) is less than 5 day(s) minimum'])
            expect(subject.errors).to eq([])
            expect(initial_application.aasm_state).to eq :active
          end
        end

        context 'When business_policy_satisfied_for? OR is_application_eligible? is false AND may_submit_for_review? is true' do
          context 'state is not draft' do
            it 'should return error' do
              allow(subject).to receive(:business_policy_satisfied_for?).and_return(false)
              allow(initial_application).to receive(:may_submit_for_review?).and_return(true)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages).to eq({})
              expect(subject.errors).to include a_string_matching /Event 'submit_for_review' cannot transition from 'active'./
              expect(initial_application.aasm_state).to eq :active
            end
          end

          context 'state is draft' do
            before { initial_application.update_attribute(:aasm_state, 'draft') }
            it 'should return notice, warnings and state could not be changed' do
              allow(initial_application).to receive(:open_enrollment_length).and_return(4)
              allow(initial_application).to receive(:may_submit_for_review?).and_return(true)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully submitted for review.')
              expect(subject.messages['warnings']).to eq(['open enrollment period length 4 day(s) is less than 5 day(s) minimum'])
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :pending
            end
          end
        end

        context 'When business_policy_satisfied_for?? AND is_application_eligible? are true' do
          context 'when benefit_application may_approve_application? is false' do
            it 'should return notice Plan Year could not be processed' do
              allow(initial_application).to receive(:may_approve_application?).and_return(false)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year could not be processed')
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :active
            end
          end

          context 'when benefit_application may_approve_application? is true and state is active then' do
            it 'should return error' do
              allow(initial_application).to receive(:may_approve_application?).and_return(true)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages).to eq({})
              expect(subject.errors).to include a_string_matching /Event 'auto_approve_application' cannot transition from 'active'./
              expect(initial_application.aasm_state).to eq :active
            end
          end

          context 'when benefit_application may_approve_application? is true and state is draft then' do
            before { initial_application.update_attributes(aasm_state: 'draft') }

            it 'should return error if today is less than open_enrollment_period' do
              allow(initial_application).to receive(:may_submit_for_review?).and_return(true)
              allow(subject).to receive(:today).and_return(initial_application.open_enrollment_period.begin - 1.year)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages).to eq({})
              expect(subject.errors).to eq(['Employer(s) Plan Year date has not matched.'])
              expect(initial_application.aasm_state).to eq :approved
            end

            it 'should return notice, warnings and state could not be changed' do
              allow(initial_application).to receive(:may_submit_for_review?).and_return(true)
              subject.force_submit_application
              initial_application.reload
              expect(subject.messages['notice']).to eq('Employer(s) Plan Year was successfully published.')
              expect(subject.errors).to eq([])
              expect(initial_application.aasm_state).to eq :enrollment_open
            end
          end
        end
      end

      context "renewal application in draft state" do

        let(:scheduled_event)  {BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents}

        let!(:renewal_application)  { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application).renew_application[1] }

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(renewal_application) }

        context "today is prior to date for force publish" do
          before(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 8, 15))
          end

          after(:each) do
            TimeKeeper.set_date_of_record_unprotected!(Date.today)
          end

          it "should not change the benefit application" do
            scheduled_event.advance_day(TimeKeeper.date_of_record)
            expect(renewal_application.aasm_state).to eq :draft
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
          let(:benefit_sponsorship_state) { :initial_enrollment_open }
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
        let(:benefit_sponsorship_state) { :initial_enrollment_open }

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
        let(:end_date) { TimeKeeper.date_of_record.next_month }

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
        let(:end_date) { TimeKeeper.date_of_record.prev_day }

        subject { BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application) }

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
        let(:benefit_sponsorship_state) { :initial_enrollment_ineligible }
        let(:today) { current_effective_date - 7.days }
        let(:oe_end_date) { current_effective_date - 5.days }

        it 'should extend open enrollment' do 
          expect(initial_application.aasm_state).to eq :enrollment_ineligible
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :initial_enrollment_ineligible
          subject.extend_open_enrollment(oe_end_date)
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_extended
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
          expect(initial_application.open_enrollment_period.max).to eq oe_end_date
        end
      end

      context 'when application canceled due to ineligibility' do
        let(:aasm_state) { :canceled }
        let(:benefit_sponsorship_state) { :applicant }
        let(:today) { current_effective_date + 2.days }
        let(:oe_end_date) { current_effective_date + 5.days }

        before do
          benefit_sponsorship.workflow_state_transitions.create(from_state: 'initial_enrollment_ineligible', to_state: 'applicant') 
        end

        it 'should extend open enrollment' do 
          expect(initial_application.aasm_state).to eq :canceled
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :applicant
          subject.extend_open_enrollment(oe_end_date)
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_extended
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
          expect(initial_application.open_enrollment_period.max).to eq oe_end_date
        end
      end

      context 'when application open enrollment closed' do
        let(:aasm_state) { :enrollment_closed }
        let(:benefit_sponsorship_state) { :initial_enrollment_closed }
        let(:today) { current_effective_date - 8.days }
        let(:oe_end_date) { current_effective_date - 5.days }

        it 'should extend open enrollment' do 
          expect(initial_application.aasm_state).to eq :enrollment_closed
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :initial_enrollment_closed
          subject.extend_open_enrollment(oe_end_date)
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_extended
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
          expect(initial_application.open_enrollment_period.max).to eq oe_end_date
        end
      end

      context 'when application open enrollment open' do
        let(:aasm_state) { :enrollment_open }
        let(:benefit_sponsorship_state) { :initial_enrollment_open }
        let(:today) { current_effective_date - 13.days }
        let(:oe_end_date) { current_effective_date - 5.days }

        it 'should extend open enrollment' do 
          expect(initial_application.aasm_state).to eq :enrollment_open
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
          subject.extend_open_enrollment(oe_end_date)
          initial_application.reload
          expect(initial_application.aasm_state).to eq :enrollment_extended
          expect(initial_application.benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
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
      let(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_package)}
      let(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id) }
      let(:census_employee) { FactoryGirl.create(:census_employee,
        employer_profile: benefit_sponsorship.profile,
        benefit_sponsorship: benefit_sponsorship,
        benefit_group_assignments: [benefit_group_assignment]
      )}
      let(:person){ FactoryGirl.create(:person, :with_family)}
      let(:family) {person.primary_family}

      let!(:hbx_enrollment) {  FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product,
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

      let!(:dental_hbx_enrollment) {  FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product,
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
