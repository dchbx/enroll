require 'rails_helper'

describe 'ModelEvents::EmployeeWaiverConfirmation' do

  let(:model_event)  { "employee_waiver_confirmation" }
  let(:notice_event) { "employee_waiver_confirmation" }
  let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:open_enrollment_start_on) {(TimeKeeper.date_of_record - 1.month).beginning_of_month}
  let!(:employer) { FactoryGirl.create(:employer_with_planyear, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year, plan_year_state: "active") }
  let!(:census_employee){   FactoryGirl.create(:census_employee, employer_profile: employer)  }
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer, census_employee_id: census_employee.id, person: person) }
  let!(:model_instance)   { FactoryGirl.create(:hbx_enrollment,
                                          household: person.primary_family.active_household,
                                          coverage_kind: "health",
                                          kind: "employer_sponsored",
                                          benefit_group_id: census_employee.employer_profile.plan_years.first.benefit_groups.first.id,
                                          employee_role_id: employee_role.id,
                                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                          aasm_state: "shopping"
  ) }


  describe "ModelEvent" do
    context "when employee waives coverage" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:hbx_enrollment_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_waiver_confirmation, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.waive_coverage!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when employee waives coverage" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:employee_waiver_confirmation, model_instance, {}) }

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
        subject.hbx_enrollment_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let!(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let!(:payload)   { {
      "event_object_kind" => "HbxEnrollment",
      "event_object_id" => model_instance.id
    } }
    let(:merge_model) { subject.construct_notice_object }
    let(:benefit_group_assignment) { double(hbx_enrollment: model_instance, active_hbx_enrollments: [model_instance]) }


    context "when notice event received" do
      before do
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

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer.organization.legal_name
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end

      it "should return waived effective on date" do
        allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
        allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([model_instance])
        waived_on = census_employee.active_benefit_group_assignment.hbx_enrollments.first.updated_at
        expect(waived_on).to eq model_instance.updated_at
      end
    end
  end
end

