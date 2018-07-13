require 'rails_helper'

describe 'ModelEvents::InitialEmployerApplicationDenied' do

  let(:model_event) { "application_denied" }
  let(:notice_event) { "initial_employer_application_denied" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let!(:employer) { create(:employer_with_planyear, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year, plan_year_state: 'enrolling') }
  let!(:model_instance) { employer.plan_years.first }

  describe "ModelEvent" do
    context "when initial employer application is denied" do
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
    context "when initial application denied" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:application_denied, model_instance, {}) }

      it "should trigger model event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_application_denied"
          expect(payload[:employer_id]).to eq employer.send(:hbx_id).to_s
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
          "employer_profile.plan_year.current_py_oe_start_date",
          "employer_profile.plan_year.current_py_start_date",
          "employer_profile.plan_year.enrollment_errors",
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
        model_instance.advance_date!
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
      it "should build return plan year open enrollment start date" do
        expect(merge_model.plan_year.current_py_oe_start_date).to eq model_instance.open_enrollment_start_on.strftime('%m/%d/%Y')
      end
      it "should return plan year start date" do
        expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end
      it "should return broker status" do
        expect(merge_model.broker_present?).to be_falsey
      end
      it "should return enrollment errors" do
        enrollment_errors = [] 
        enrollment_errors << "At least 75% of your eligible employees enrolled in your group health coverage or waive due to having other coverage"
        expect(merge_model.plan_year.enrollment_errors).to include(enrollment_errors.join(' AND/OR '))
      end
    end
  end
end
