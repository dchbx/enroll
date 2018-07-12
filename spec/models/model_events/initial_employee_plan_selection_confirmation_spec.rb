require 'rails_helper'

describe 'ModelEvents::InitialEmployeePlanSelectionConfirmation', dbclean: :around_each  do
  let(:model_event)  { "initial_employee_plan_selection_confirmation" }
  let(:notice_event) { "initial_employee_plan_selection_confirmation" }
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
  let!(:model_instance) { create(:employer_with_planyear, plan_year_state: 'enrolled', start_on: start_on, aasm_state: 'eligible')}
  let!(:benefit_group) { model_instance.published_plan_year.benefit_groups.first}
  let!(:organization) { model_instance.organization }
  let!(:census_employee){ employee = FactoryGirl.create :census_employee, employer_profile: model_instance
    employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
    employee
  }
    let!(:person) { FactoryGirl.create(:person) }

    let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: model_instance, census_employee_id: census_employee.id, person: person) }

  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let!(:hbx_enrollment) { FactoryGirl.build(:hbx_enrollment, household: family.active_household, benefit_group_assignment_id: benefit_group.benefit_group_assignments.first.id, benefit_group_id: benefit_group.id, effective_on: start_on)}

 
  describe "ModelEvent" do
    context "when ER made binder payment " do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:employer_profile_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :initial_employee_plan_selection_confirmation, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.binder_credited!
      end
    end

    context "when employer is transitioned/updated to a different state other than binder_paid " do
      it "should not trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).not_to receive(:employer_profile_update)
        end
        model_instance.enrollment_expired!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when ER made binder payment " do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employee_plan_selection_confirmation, model_instance, {}) }
      before do
         allow_any_instance_of(BenefitGroupAssignment).to receive('hbx_enrollment').and_return(hbx_enrollment)
         allow_any_instance_of(CensusEmployee).to receive(:employee_role).and_return(employee_role)
      end
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.initial_employee_plan_selection_confirmation"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq hbx_enrollment.id.to_s
        end
        subject.employer_profile_update(model_event)
      end
    end
  end

   describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "employee_profile.notice_date",
          "employee_profile.employer_name",
          "employee_profile.plan_year.current_py_start_date",
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
        "event_object_kind" => "EmployerProfile",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq model_instance.legal_name
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end
end