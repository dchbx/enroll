require 'rails_helper'

describe 'ModelEvents::ZeroEmployeesOnRoster', dbclean: :around_each  do

  let(:model_event)  { "zero_employees_on_roster" }
  let(:notice_event) { "zero_employees_on_roster_notice" }
  let!(:employer){ FactoryGirl.create :employer_profile}
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.months}
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'draft', open_enrollment_start_on: TimeKeeper.date_of_record.next_day) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }

  describe "ModelEvent" do

    context "when zero employees on the roster" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :zero_employees_on_roster, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.force_publish!
      end
    end
  end

  describe "NoticeTrigger" do

    context "when zero employees on the roster" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:zero_employees_on_roster, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.zero_employees_on_roster_notice"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
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
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.plan_year.current_py_start_date",
        "employer_profile.plan_year.current_py_oe_end_date",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
      "event_object_kind" => "PlanYear",
      "event_object_id" => model_instance.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.force_publish!
      end

      it "should retrun merge mdoel" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer.legal_name
      end

      it "should return plan year start date" do
        expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end

    end
  end
end