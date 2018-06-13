require 'rails_helper'

describe 'ModelEvents::EmployeePlanCoverageSelected' do

  let(:model_event)  { "application_coverage_selected" }
  let(:notice_event) { "employee_plan_selection_confirmation_sep_new_hire" }
  let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:open_enrollment_start_on) {(TimeKeeper.date_of_record - 1.month).beginning_of_month}
  let!(:employer) { FactoryGirl.create(:employer_with_planyear, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year, plan_year_state: "active") }
  let!(:census_employee){   FactoryGirl.create(:census_employee, employer_profile: employer)  }
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:role) {  FactoryGirl.create(:employee_role, person: person, census_employee: census_employee, employer_profile: employer) }
  let!(:model_instance)   { FactoryGirl.create(:hbx_enrollment,
                                           household: person.primary_family.active_household,
                                          coverage_kind: "health",
                                          kind: "employer_sponsored",
                                          benefit_group_id: census_employee.employer_profile.plan_years.first.benefit_groups.first.id,
                                          employee_role_id: role.id,
                                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                          aasm_state: "shopping"
  ) }

  describe "ModelEvent" do
    context "when employee plan coverage selected" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:hbx_enrollment_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :application_coverage_selected, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.select_coverage!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when employee plan coverage selected" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:application_coverage_selected, model_instance, {}) }

      it "should trigger notice event" do
        allow(model_instance).to receive(:is_shop?).and_return(true)
        allow(model_instance).to receive(:enrollment_kind).and_return('special_enrollment')
        allow(model_instance).to receive(:census_employee).and_return(census_employee)
        allow(census_employee).to receive(:employee_role).and_return(role)
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_plan_selection_confirmation_sep_new_hire"
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

    context "when notice event received" do
      let(:employer_profile2) { model_instance.census_employee.employee_role.employer_profile  }

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(model_instance).to receive(:is_shop?).and_return(true)
        allow(model_instance).to receive(:enrollment_kind).and_return('special_enrollment')
        allow(model_instance).to receive(:census_employee).and_return(census_employee)
        allow(census_employee).to receive(:employee_role).and_return(role)
        allow(subject).to receive(:resource).and_return(model_instance.census_employee.employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        allow(role).to receive(:person).and_return(person)
        model_instance.select_coverage!
      end

      it "should build the data elements for the notice" do

        merge_model = subject.construct_notice_object
        expect(merge_model).to be_a(recipient.constantize)
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
        expect(merge_model.employer_name).to eq employer_profile2.legal_name
        expect(merge_model).to be_a(recipient.constantize)
        expect(merge_model.employer_name).to eq employer.organization.legal_name
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end