require 'rails_helper'

describe 'ModelEvents::InitialEmployerFirstRemainderToPublishPlanYear', dbclean: :around_each do

  let(:model_event) { "initial_employer_first_reminder_to_publish_plan_year" }
  let(:notice_event) { "initial_employer_first_reminder_to_publish_plan_year" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:employer){ create :employer_profile}
  let!(:model_instance) { build(:plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'draft') }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance) }
  let!(:date_mock_object) { double("Date", day: Settings.aca.shop_market.initial_application.advertised_deadline_of_month - 2 )}

  describe "ModelEvent" do
    context "when initial employer 2 days prior to soft dead line" do
      it "should trigger model event" do
        expect_any_instance_of(Observers::Observer).to receive(:trigger_notice).with(recipient: employer, event_object: model_instance, notice_event: model_event).and_return(true)
        PlanYear.date_change_event(date_mock_object)
      end
    end
  end

  describe "NoticeTrigger" do
    context "when initial employer 2 days prior to soft dead line" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employer_first_reminder_to_publish_plan_year, PlanYear, {}) }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_first_reminder_to_publish_plan_year"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_date_change(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.plan_year.current_py_start_date",
        "employer_profile.plan_year.initial_py_publish_advertise_deadline",
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
        PlanYear.date_change_event(date_mock_object)
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

      it "should return advertised deadline of month" do
        expect(merge_model.plan_year.initial_py_publish_advertise_deadline).to eq Date.new(model_instance.start_on.prev_month.year, model_instance.start_on.prev_month.month, Settings.aca.shop_market.initial_application.advertised_deadline_of_month).strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end
