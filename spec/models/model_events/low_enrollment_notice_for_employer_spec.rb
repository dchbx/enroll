require 'rails_helper'

describe 'ModelEvents::LowEnrollmentNoticeForEmployer' do


  let(:model_event) { "low_enrollment_notice_for_employer" }
  let!(:employer) { create(:employer_with_planyear, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year, plan_year_state: 'active') }
  let!(:model_instance) { build(:renewing_plan_year, employer_profile: employer, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month, aasm_state: 'renewing_enrolling') }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance) }
  let!(:date_mock_object) { double("Date", day: 18)}

  before do
    employer.renewing_plan_year.update_attributes(open_enrollment_end_on: TimeKeeper.date_of_record+2.days)
  end

  describe "ModelEvent" do
    around(:each) do |example|
      example.run
      DatabaseCleaner.clean_with(:truncation, :except => %w[translations])
    end
    context "organizations for low enrollment" do
      it "should trigger model event" do
        expect_any_instance_of(Observers::Observer).to receive(:trigger_notice).with(recipient: employer, event_object: model_instance, notice_event: model_event).and_return(true)
        PlanYear.date_change_event(date_mock_object)
      end
    end
  end

  describe "NoticeTrigger" do
    after(:each) do
      DatabaseCleaner.clean_with(:truncation, :except => %w[translations])
    end
    context "organizations for low enrollment" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:low_enrollment_notice_for_employer, PlanYear, {}) }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.low_enrollment_notice_for_employer"
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
          "employer_profile.plan_year.current_py_start_on",
          "employer_profile.plan_year.current_py_oe_end_date",
          "employer_profile.plan_year.renewal_py_start_date",
          "employer_profile.plan_year.renewal_py_oe_end_date",
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

    let(:merge_model) { subject.construct_notice_object }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
        PlanYear.date_change_event(date_mock_object)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
         expect(merge_model.employer_name).to eq employer.legal_name
      end

      it "should return renewing plan year open enrollment end date" do
         expect(merge_model.plan_year.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end

      it "should return renewing plan year start on date" do
        expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end
    end
  end
end
