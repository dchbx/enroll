require 'rails_helper'

describe 'ModelEvents::RenewalEmployerReminderToPublishPlanYearNotification', dbclean: :around_each do

  let(:model_event) { "renewal_plan_year_first_reminder_before_soft_dead_line" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:employer) { create(:employer_with_planyear, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month.prev_year, plan_year_state: 'active') }
  let!(:model_instance) { build(:renewing_plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'renewing_draft') }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance) }
  let!(:date_mock_object) { double("Date", day: Settings.aca.shop_market.renewal_application.application_submission_soft_deadline - 2)}
  let!(:employer_staff_role) {FactoryGirl.create(:employer_staff_role, aasm_state:'is_active', employer_profile_id: employer.id)}
  let(:person) { FactoryGirl.create(:person,employer_staff_roles:[employer_staff_role])}

  describe "ModelEvent" do
    context "when renewal employer 2 days prior to soft dead line" do
      it "should trigger model event" do
        expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employer, event_object: model_instance, notice_event: model_event).and_return(true)
        PlanYear.date_change_event(date_mock_object)
      end
    end
  end

  describe "NoticeTrigger" do
    context "when renewal application created" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:renewal_plan_year_first_reminder_before_soft_dead_line, PlanYear, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_plan_year_first_reminder_before_soft_dead_line"
          expect(payload[:employer_id]).to eq employer.send(:hbx_id).to_s
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
          "employer_profile.plan_year.renewal_py_start_date",
          "employer_profile.plan_year.renewal_py_submit_soft_due_date",
          "employer_profile.plan_year.renewal_py_oe_end_date",
          "employer_profile.plan_year.current_py_start_on.year",
          "employer_profile.plan_year.renewal_py_start_on.year",
          "employer_profile.broker.primary_fullname",
          "employer_profile.broker.organization",
          "employer_profile.broker.phone",
          "employer_profile.broker.email",
          "employer_profile.broker_present?"
      ]
    }

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

      it "should build the data elements for the notice" do
        merge_model = subject.construct_notice_object
        expect(merge_model).to be_a(recipient.constantize)
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
        expect(merge_model.employer_name).to eq employer.legal_name
        expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
        expect(merge_model.plan_year.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
        expect(merge_model.broker_present?).to be_falsey
        expect(merge_model.plan_year.renewal_py_start_on).to eq model_instance.start_on
      end
    end
  end
end
