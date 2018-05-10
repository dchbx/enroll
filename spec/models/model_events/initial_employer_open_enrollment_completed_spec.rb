require 'rails_helper'

describe 'ModelEvents::InitialEmployerOpenEnrollmentCompleted', dbclean: :around_each  do

  let(:model_event)  { "initial_employer_open_enrollment_completed" }
  let(:notice_event) { "initial_employer_open_enrollment_completed" }
  let(:employer){ create :employer_profile}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:model_instance) { build(:plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'enrolling') }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }

  describe "ModelEvent" do

    before do
      allow(model_instance).to receive(:is_enrollment_valid?).and_return true
      TimeKeeper.set_date_of_record_unprotected!(model_instance.open_enrollment_end_on.next_day)
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    context "when initial employer open enrollment is completed" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :initial_employer_open_enrollment_completed, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.advance_date!
      end
    end
  end

  describe "NoticeTrigger" do

    context "when initial employer OE completed" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employer_open_enrollment_completed, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_employer_open_enrollment_completed"
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
        "employer_profile.plan_year.binder_payment_due_date",
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
        allow(model_instance).to receive(:is_enrollment_valid?).and_return true
        TimeKeeper.set_date_of_record_unprotected!(model_instance.open_enrollment_end_on.next_day)
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.advance_date!
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
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

      it "should return binder payment due date" do
        binder_due_date = PlanYear.calculate_open_enrollment_date(model_instance.start_on)[:binder_payment_due_date]
        expect(merge_model.plan_year.binder_payment_due_date).to eq binder_due_date.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end

    end
  end
end