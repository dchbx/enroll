require "rails_helper"
require File.join(File.dirname(__FILE__), "..", "support/benefit_sponsors_site_spec_helpers")
require File.join(File.dirname(__FILE__), "..", "support/benefit_sponsors_product_spec_helpers")
require File.join(File.dirname(__FILE__), "..", "..", "app", "data_migrations", "modify_benefit_application")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ModifyBenefitApplication, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"
  include_context "setup employees with benefits"

  let(:given_task_name) { "modify_benefit_application" }
  subject { ModifyBenefitApplication.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name", dbclean: :after_each do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "modifying benefit application", dbclean: :after_each do

    let(:start_on)  { current_effective_date }
    let(:effective_period)  { start_on..start_on.next_year.prev_day }
    let(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_package) }

    let(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id) }
    let(:census_employee) { FactoryBot.create(:census_employee,
      employer_profile: abc_profile,
      benefit_group_assignments: [benefit_group_assignment]
    )}
    let(:person) { FactoryBot.create(:person, :with_family) }
    let(:family) { person.primary_family }
    let!(:enrollment) {  FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                        household: family.active_household,
                        family: family,
                        aasm_state: "coverage_selected",
                        effective_on: start_on,
                        rating_area_id: predecessor_application.recorded_rating_area_id,
                        sponsored_benefit_id: predecessor_application.benefit_packages.first.health_sponsored_benefit.id,

                        # sponsored_benefit_id:sponsored_benefit.id,
                        sponsored_benefit_package_id:predecessor_application.benefit_packages.first.id,
                        benefit_sponsorship_id:predecessor_application.benefit_sponsorship.id,
                        benefit_group_assignment_id: benefit_group_assignment.id,
                        employee_role_id: employee_role.id)
    }

    around do |example|
      ClimateControl.modify fein: abc_organization.fein do
        example.run
      end
    end

    context "extend open enrollment" do
        let!(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
        let!(:effective_period) { start_on..start_on.next_year.prev_day }
        let!(:ineligible_benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, benefit_sponsorship: benefit_sponsorship, aasm_state: "enrollment_ineligible", effective_period: effective_period)}

        around do |example|
          ClimateControl.modify action: 'extend_open_enrollment', effective_date: start_on.strftime("%m/%d/%Y"), oe_end_date: start_on.prev_day.strftime("%m/%d/%Y") do
            example.run
          end
        end

        it "should extend open enrollment from enrollment ineligible" do
          expect(ineligible_benefit_application.aasm_state).to eq :enrollment_ineligible
          subject.migrate
          ineligible_benefit_application.reload
          benefit_sponsorship.reload
          expect(ineligible_benefit_application.open_enrollment_period.max).to eq start_on.prev_day
          expect(ineligible_benefit_application.aasm_state).to eq :enrollment_extended
        end

        it "should extend open enrollment from enrollment open" do
          ineligible_benefit_application.update_attributes!(aasm_state: "enrollment_open")
          expect(ineligible_benefit_application.aasm_state).to eq :enrollment_open
          subject.migrate
          ineligible_benefit_application.reload
          benefit_sponsorship.reload
          expect(ineligible_benefit_application.open_enrollment_period.max).to eq start_on.prev_day
          expect(ineligible_benefit_application.aasm_state).to eq :enrollment_extended
        end

        it "should not extend open enrollment from draft" do
          ineligible_benefit_application.update_attributes!(aasm_state: "draft")
          expect(ineligible_benefit_application.aasm_state).to eq :draft
          expect { subject.migrate }.to raise_error("Unable to find benefit application!!")
        end
    end

    context "Update assm state to enrollment open" do
      context "update aasm state to enrollment open for non renewing ER" do
        let(:effective_date) { predecessor_application.effective_period.min }

        around do |example|
          ClimateControl.modify effective_date: effective_date.strftime("%m/%d/%Y"), action: 'begin_open_enrollment' do
            example.run
          end
        end

        it "should update the benefit application" do
          predecessor_application.update_attributes!(aasm_state: "enrollment_ineligible", benefit_packages: [])
          # benefit_sponsorship.update_attributes!(aasm_state: "initial_enrollment_ineligible")
          expect(predecessor_application.aasm_state).to eq :enrollment_ineligible
          # expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_ineligible
          subject.migrate
          predecessor_application.reload
          benefit_sponsorship.reload
          expect(predecessor_application.aasm_state).to eq :enrollment_open
          # expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_open
        end

        it "should not update the benefit application" do
          expect { subject.migrate }.to raise_error(RuntimeError)
          expect { subject.migrate }.to raise_error("FAILED: Unable to find application or application is in invalid state")
        end
      end

      context "update aasm state to enrollment open but not sponsoship for renewing ER" do
        let(:effective_date) { predecessor_application.effective_period.min }

        before do
          allow_any_instance_of(BenefitSponsors::BenefitApplications::BenefitApplication).to receive(:is_renewing?).and_return(true)
        end

        around do |example|
          ClimateControl.modify effective_date: effective_date.strftime("%m/%d/%Y"), action: 'begin_open_enrollment' do
            example.run
          end
        end

        it "should update the benefit application" do
          predecessor_application.update_attributes!(aasm_state: :enrollment_ineligible, benefit_packages: [])
          # benefit_sponsorship.update_attributes!(aasm_state: "initial_enrollment_ineligible")
          expect(predecessor_application.aasm_state).to eq :enrollment_ineligible
          # expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_ineligible
          subject.migrate
          predecessor_application.reload
          benefit_sponsorship.reload
          expect(predecessor_application.aasm_state).to eq :enrollment_open
          # expect(benefit_sponsorship.aasm_state).to eq :initial_enrollment_ineligible
        end
      end
    end

    context "terminate benefit application", dbclean: :after_each do
      let(:termination_date) { renewal_application.effective_period.min.next_month.next_day }
      let(:end_on)           { renewal_application.effective_period.min.next_month.end_of_month }
      let(:termination_kind) { 'voluntary' }
      let(:termination_reason) { 'Company went out of business/bankrupt' }

      before do
        renewal_application.update_attributes!(aasm_state: "active", benefit_packages: [])
        subject.migrate
        renewal_application.reload
      end

      around do |example|
        ClimateControl.modify(
          off_cycle_renewal: 'true',
          termination_notice: 'true',
          action: 'terminate',
          termination_date: termination_date.strftime("%m/%d/%Y"),
          termination_kind: termination_kind,
          termination_reason: termination_reason,
          end_on: end_on.strftime("%m/%d/%Y")
        ) do
          example.run
        end
      end

      it "should terminate the benefit application" do
        expect(renewal_application.aasm_state).to eq :terminated
      end

      it "should transition benefit sponsorship to applicant" do
        benefit_sponsorship.reload
        expect(benefit_sponsorship.aasm_state).to eq :applicant
      end

      it "should update end on date on benefit application" do
        expect(renewal_application.end_on).to eq end_on
      end

      it "should update end on date on benefit application" do
        expect(renewal_application.terminated_on).to eq termination_date
      end

      it "should update the termination kind" do
        expect(renewal_application.termination_kind).to eq termination_kind
      end

      it "should update the termination reason" do
        expect(renewal_application.termination_reason).to eq termination_reason
      end

      it "should terminate any active employee enrollments" do
        renewal_application.hbx_enrollments.each { |hbx_enrollment| expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"}
      end

      it "should terminate any active employee enrollments with termination date as on Benefit Application" do
        renewal_application.hbx_enrollments.each { |hbx_enrollment| expect(hbx_enrollment.terminated_on).to eq end_on }
      end
    end

    context "cancel benefit application", dbclean: :after_each do
      let(:past_start_on) {start_on + 2.months}
      let!(:past_effective_period) {past_start_on..past_start_on.next_year.prev_day }
      let!(:mid_plan_year_effective_date) {start_on.next_month}
      let!(:range_effective_period) { mid_plan_year_effective_date..mid_plan_year_effective_date.next_year.prev_day }
      let!(:draft_benefit_application) do
        current_benefit_market_catalog
        FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, benefit_sponsorship: benefit_sponsorship, aasm_state: :imported, effective_period: past_effective_period).tap do |application|
          application.benefit_sponsor_catalog.save!
        end
      end
      let!(:import_draft_benefit_application) do
        current_benefit_market_catalog
        FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, benefit_sponsorship: benefit_sponsorship, aasm_state: :imported, effective_period: range_effective_period).tap do |application|
          application.benefit_sponsor_catalog.save!
        end
      end

      around do |example|
        ClimateControl.modify plan_year_start_on: import_draft_benefit_application.effective_period.min.strftime("%m/%d/%Y"), action: 'cancel' do
          example.run
        end
      end

      it "does not cancel non-imported draft benefit applications" do
        subject.migrate
        expect(draft_benefit_application.reload.aasm_state).to eq :imported
      end

      it "cancels import draft benefit applications" do
        subject.migrate
        expect(import_draft_benefit_application.reload.aasm_state).to eq :canceled
      end
    end

    context "Should update effective period and approve initial benefit application", dbclean: :after_each do
      let(:current_effective_date)   { (TimeKeeper.date_of_record + 2.months).beginning_of_month }

      let(:effective_date) { current_effective_date.prev_year }
      let(:new_start_date) { effective_date.next_month }
      let(:new_end_date) { new_start_date + 1.year }
      let(:display_name) { 'Employee' }
      let!(:contribution_unit)  { predecessor_application.benefit_packages[0].health_sponsored_benefit.contribution_model.contribution_units.where(display_name: display_name).first }
      around do |example|
        ClimateControl.modify(
          action: 'update_effective_period_and_approve',
          effective_date: effective_date.strftime("%m/%d/%Y"),
          new_start_date: new_start_date.strftime("%m/%d/%Y"),
          new_end_date: new_end_date.strftime("%m/%d/%Y")
        ) do
          example.run
        end
      end

      it "should update the initial benefit application and transition the benefit sponsorship" do
        predecessor_application.update_attributes!(aasm_state: "draft")
        expect(predecessor_application.effective_period.min.to_date).to eq effective_date
        subject.migrate
        predecessor_application.reload
        benefit_sponsorship.reload
        expect(predecessor_application.start_on.to_date).to eq new_start_date
        expect(predecessor_application.end_on.to_date).to eq new_end_date
        expect(predecessor_application.aasm_state).to eq :approved
        expect(predecessor_application.benefit_sponsorship.aasm_state).to eq :applicant
        cl = predecessor_application.benefit_packages[0].health_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: display_name).first
        expect(contribution_unit.id).to eq cl.contribution_unit_id
      end

      it "should not update the initial benefit application" do
        expect { subject.migrate }.to raise_error(RuntimeError)
        expect { subject.migrate }.to raise_error("No benefit application found.")
      end
    end

    context "Should force publish the benefit application", dbclean: :after_each do
      let(:effective_date) { predecessor_application.effective_period.min }

      before do
        allow(benefit_sponsorship.profile).to receive(:employer_attestation).and_return(double(:blank? => true)) if Settings.site.key == :cca
      end

      around do |example|
        ClimateControl.modify effective_date: effective_date.strftime("%m/%d/%Y"), action: 'force_submit_application' do
          example.run
        end
      end

      it "should update the benefit application and transition the benefit sponsorship" do
        predecessor_application.update_attributes!(aasm_state: "draft")
        predecessor_application.update_attributes!(fte_count: 3)
        expect(predecessor_application.effective_period.min.to_date).to eq effective_date
        subject.migrate
        predecessor_application.reload
        benefit_sponsorship.reload
        expect(predecessor_application.effective_period.min.to_date).to eq effective_date
        expect(predecessor_application.aasm_state).to eq :enrollment_open
        expect(predecessor_application.benefit_sponsorship.aasm_state).to eq :applicant
      end

      it "should not update the benefit application" do
        benefit_sponsorship.benefit_applications.delete_all
        expect { subject.migrate }.to raise_error(RuntimeError)
        expect { subject.migrate }.to raise_error("Found 0 benefit applications with that start date")
      end
    end

    context "Should update effective period and approve renewing benefit application", dbclean: :after_each do
      let(:effective_date) { renewal_application.effective_period.min }
      let(:new_start_date) { (effective_date + 2.months).beginning_of_month}
      let(:new_end_date) { new_start_date + 1.year }
      let(:current_effective_date)  { TimeKeeper.date_of_record }
      let(:display_name) { 'Employee' }
      let!(:contribution_unit)  { renewal_application.benefit_packages[0].health_sponsored_benefit.contribution_model.contribution_units.where(display_name: display_name).first }

      around do |example|
        ClimateControl.modify(
          action: 'update_effective_period_and_approve',
          effective_date: effective_date.strftime("%m/%d/%Y"),
          new_start_date: new_start_date.strftime("%m/%d/%Y"),
          new_end_date: new_end_date.strftime("%m/%d/%Y")
        ) do
          example.run
        end
      end

      it "should update the renewing benefit application and transition the benefit sponsorship" do
        renewal_application.update_attributes!(aasm_state: "draft")
        expect(renewal_application.effective_period.min.to_date).to eq effective_date
        subject.migrate
        renewal_application.reload
        benefit_sponsorship.reload
        expect(renewal_application.start_on.to_date).to eq new_start_date
        expect(renewal_application.end_on.to_date).to eq new_end_date
        expect(renewal_application.aasm_state).to eq :approved
        expect(renewal_application.benefit_sponsorship.aasm_state).to eq :active
        cl = renewal_application.benefit_packages[0].health_sponsored_benefit.sponsor_contribution.contribution_levels.where(display_name: display_name).first
        expect(contribution_unit.id).to eq cl.contribution_unit_id
      end

      it "should not update the renewing benefit application" do
        renewal_application.update_attributes!(aasm_state: "active")
        expect { subject.migrate }.to raise_error(RuntimeError)
        expect { subject.migrate }.to raise_error("No benefit application found.")
      end
    end

    context "should trigger termination notice", dbclean: :after_each do

      let(:termination_date) { renewal_application.effective_period.min.next_month.next_day }
      let(:end_on)           { termination_date.next_month.end_of_month }

      around do |example|
        ClimateControl.modify(
          off_cycle_renewal: 'true',
          termination_notice: 'true',
          action: 'terminate',
          termination_date: termination_date.strftime("%m/%d/%Y"),
          end_on: end_on.strftime("%m/%d/%Y")
        ) do
          example.run
        end
      end

      let(:model_instance) { renewal_application }

      before do
        renewal_application.update_attributes!(aasm_state: "active", benefit_packages: [])
      end

      context "should trigger termination notice to employer and employees" do
        it "should trigger model event" do
          model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
            expect(observer).to receive(:process_application_events) do |_instance, model_event|
              expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :group_termination_confirmation_notice, :klass_instance => model_instance, :options => {})
            end
          end
          subject.migrate
        end
      end
    end
   end
end