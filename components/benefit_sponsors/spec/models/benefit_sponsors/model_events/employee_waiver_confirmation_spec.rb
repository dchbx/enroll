require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe 'BenefitSponsors::ModelEvents::EmployeeWaiverConfirmation', dbclean: :around_each  do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:model_event)  { "employee_waiver_confirmation" }

  let(:aasm_state) { "enrollment_eligible" }
  let!(:person){ FactoryBot.create(:person, :with_family)}
  let!(:family) {person.primary_family}
  let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship,  active_benefit_group_assignment: current_benefit_package.id, employer_profile: abc_profile) }
  
  let!(:model_instance) { 
    hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                        household: family.active_household,
                        family: family,
                        aasm_state: "coverage_selected",
                        effective_on: initial_application.start_on,
                        kind: "employer_sponsored",
                        rating_area_id: initial_application.recorded_rating_area_id,
                        sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                        benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                        employee_role_id: employee_role.id) 
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }

  describe "ModelEvent", dbclean: :around_each  do
    context "when employee waives coverage" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
          expect(observer).to receive(:process_enrollment_events) do |_model_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_waiver_confirmation, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.waive_coverage!
      end
    end
  end

  describe "NoticeTrigger", dbclean: :around_each  do
    context "when employee waives coverage" do
      subject { BenefitSponsors::Observers::NoticeObserver.new  }
      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:employee_waiver_confirmation, model_instance, {}) }

      it "should trigger notice event" do
        allow(model_instance).to receive(:is_shop?).and_return(true)
        allow(model_instance).to receive(:census_employee).and_return(census_employee)
        allow(census_employee).to receive(:employee_role).and_return(employee_role)
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_waiver_confirmation"
          expect(payload[:employee_role_id]).to eq model_instance.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_enrollment_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.enrollment.waiver_plan_name",
        "employee_profile.enrollment.waiver_effective_on",
        "employee_profile.enrollment_waiver_coverage_end_on",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?",
        "employee_profile.has_parent_enrollment?"
      ]
    }

    let(:enrollment) { model_instance }
    let(:waived_enrollment) do
      enrollment.waive_coverage!
      enrollment.predecessor_enrollment_id = model_instance.id
      enrollment.save!
      enrollment
    end

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let!(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let!(:payload)   { {
      "event_object_kind" => "HbxEnrollment",
      "event_object_id" => waived_enrollment.id
    } }
    let(:merge_model) { subject.construct_notice_object }
    let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }


    context "when notice event received" do
      before do
        allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([model_instance])
        allow(employee_role.census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end
      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end

      it "should return waiver plan name" do
        expect(merge_model.enrollment.waiver_plan_name).to eq model_instance.product.name
      end

      it "should return waiver coverage end on" do
        expect(merge_model.enrollment.waiver_coverage_end_on).to eq waived_enrollment.effective_on.prev_day.strftime('%m/%d/%Y')
      end

      it "should return waived effective on date" do
        waived_on = census_employee.active_benefit_group_assignment.hbx_enrollments.first.updated_at
        expect(waived_on).to eq model_instance.updated_at
      end
    end
  end
end

