require 'rails_helper'

describe 'ModelEvents::NotifyEmployeeOfInitialEmployerIneligibility', :dbclean => :after_each do
  let(:model_event)  { "application_denied" }
  let(:notice_event) { "group_ineligibility_notice_to_employee" }
  let(:employer_profile){ create :employer_profile, aasm_state: "registered"}
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let(:start_on) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }
  let!(:census_employee){ FactoryGirl.create(:census_employee, employer_profile: employer_profile)  }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile,census_employee_id: census_employee.id, person: person) }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'enrolling') }

  describe "ModelEvent" do
    context "when employer terminated from shop" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :application_denied, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.advance_date!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when employer terminated from shop" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:application_denied, model_instance, {}) }
      let(:errors) { {non_business_owner_enrollment_count: "at least 2/3 non-owner employee must enroll"} }

      it "should trigger notice event" do
        allow(model_instance).to receive(:enrollment_errors).and_return(errors)
        allow_any_instance_of(CensusEmployee).to receive(:employee_role).and_return(employee_role)
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.group_ineligibility_notice_to_employee"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_update(model_event)
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

    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }

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
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return plan year start on" do
        expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end