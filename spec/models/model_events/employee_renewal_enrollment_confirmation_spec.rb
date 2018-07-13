require 'rails_helper'
include ActionView::Helpers::NumberHelper
describe 'ModelEvents::RenewalApplicationSubmittedNotification' do

  let(:model_event) { "renewal_employee_enrollment_confirmation" }
  let(:notice_event) { "renewal_employee_enrollment_confirmation" }
  let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:open_enrollment_start_on) {(TimeKeeper.date_of_record - 1.month).beginning_of_month}
  let!(:employer) { create(:employer_with_planyear, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year, plan_year_state: 'active') }
  let(:model_instance) { build(:renewing_plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'renewing_enrolling', benefit_groups: [benefit_group], open_enrollment_end_on: TimeKeeper.date_of_record.beginning_of_day - 6.day) }
  let!(:census_employee) {
    ce = FactoryGirl.create :census_employee, employer_profile: employer, dob: TimeKeeper.date_of_record - 30.years, aasm_state: "eligible"
    person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer)
    ce.update_attributes({employee_role: employee_role})
    family = Family.find_or_build_from_employee_role(employee_role)
    ce
  }

  let(:enrollment)   { FactoryGirl.create(:hbx_enrollment,
                                          household: census_employee.employee_role.person.primary_family.active_household,
                                          coverage_kind: "health",
                                          kind: "employer_sponsored",
                                          benefit_group_id: census_employee.employer_profile.plan_years.where(aasm_state: 'active').first.benefit_groups.first.id,
                                          employee_role_id: census_employee.employee_role.id,
                                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                          aasm_state: "auto_renewing"
  )
  }
  let(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let!(:benefit_group_assign) { double("BenefitGroupAssign")}

  describe "ModelEvent" do
    context "when renewal_employee_enrollment_confirmation" do

      it "should trigger model event" do
        allow_any_instance_of(PlanYear).to receive(:eligible_to_enroll_count).and_return(1)
        allow_any_instance_of(PlanYear).to receive(:non_business_owner_enrolled).and_return(["rspec1", "rspec2"])
        allow_any_instance_of(PlanYear).to receive(:enrollment_ratio).and_return(2)
        allow_any_instance_of(CensusEmployee).to receive(:renewal_benefit_group_assignment).and_return(benefit_group_assign)
        allow(benefit_group_assign).to receive(:hbx_enrollments).and_return([enrollment])
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_enrollment_confirmation, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.advance_date!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when renewal application created" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:renewal_enrollment_confirmation, model_instance, {}) }

      it "should trigger notice event" do
        allow_any_instance_of(CensusEmployee).to receive(:renewal_benefit_group_assignment).and_return(benefit_group_assign)
        allow(benefit_group_assign).to receive(:hbx_enrollments).and_return([enrollment])
        allow_any_instance_of(PlanYear).to receive(:eligible_to_enroll_count).and_return(1)
        allow_any_instance_of(PlanYear).to receive(:non_business_owner_enrolled).and_return(["rspec1", "rspec2"])
        allow_any_instance_of(PlanYear).to receive(:enrollment_ratio).and_return(2)
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_employer_open_enrollment_completed"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        employer.census_employees.non_terminated.each do |ce|
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.renewal_employee_enrollment_confirmation"
            expect(payload[:employee_role_id]).to eq ce.employee_role_id.to_s
            expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
            expect(payload[:event_object_id]).to eq enrollment.id.to_s
          end
        end

        subject.plan_year_update(model_event)
      end
    end

    describe "NoticeBuilder" do

      let(:data_elements) {
        [
            "employee_profile.notice_date",
            "employee_profile.first_name",
            "employee_profile.last_name",
            "employee_profile.enrollment.plan_name",
            "employee_profile.enrollment.coverage_start_on",
            "employee_profile.enrollment.employee_responsible_amount",
            "employee_profile.employer_name",
            "employee_profile.enrollment.employer_responsible_amount",
            "employee_profile.broker.primary_fullname",
            "employee_profile.broker.organization",
            "employee_profile.broker.phone",
            "employee_profile.broker.email",
            "employee_profile.broker_present?"

        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }

      let(:payload)   { {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => enrollment.id
      } }
      
      context "when notice event received" do

        subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

        before do
          allow_any_instance_of(CensusEmployee).to receive(:renewal_benefit_group_assignment).and_return(benefit_group_assign)
          allow(benefit_group_assign).to receive(:hbx_enrollments).and_return([enrollment])
          allow(subject).to receive(:resource).and_return(census_employee.employee_role)
          allow(subject).to receive(:payload).and_return(payload)
          allow_any_instance_of(PlanYear).to receive(:eligible_to_enroll_count).and_return(1)
          allow_any_instance_of(PlanYear).to receive(:non_business_owner_enrolled).and_return(["rspec1", "rspec2"])
          allow_any_instance_of(PlanYear).to receive(:enrollment_ratio).and_return(2)
          allow_any_instance_of(BenefitGroupAssignment).to receive(:hbx_enrollment).and_return(enrollment)
          model_instance.advance_date!
        end

        it "should build the data elements for the notice" do
          merge_model = subject.construct_notice_object
          expect(merge_model).to be_a(recipient.constantize)
          expect(merge_model.employer_name).to eq employer.organization.legal_name
          expect(merge_model.enrollment.coverage_start_on).to eq enrollment.effective_on.strftime('%m/%d/%Y')
          expect(merge_model.enrollment.employer_responsible_amount).to eq number_to_currency(enrollment.total_employer_contribution, precision: 2)
          expect(merge_model.broker_present?).to be_falsey
        end
      end
    end
  end
end
