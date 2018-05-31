require 'rails_helper'
describe 'ModelEvents::InitialEmployerApplicationApproval' do

  let(:model_event) { "initial_application_submitted" }
  let(:notice_event) { "initial_application_submitted" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month}
  let(:open_enrollment_start_on) {(TimeKeeper.date_of_record - 1.month).beginning_of_month}
  let(:employer_profile){ create :employer_profile}
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'draft' ) }

  describe "ModelEvent" do
    before do
      allow(model_instance).to receive(:is_application_unpublishable?).and_return false
    end
    context "when initial employer's application is approved" do

      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :initial_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.publish!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when initial application is approved" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:initial_application_submitted, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.initial_application_submitted"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.zero_employees_on_roster_notice"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_update(model_event)
      end
    end

    describe "NoticeBuilder" do

      let(:data_elements) {
        [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.plan_year.current_py_start_date",
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
          "employer_id" => employer_profile.hbx_id.to_s,
          "event_object_kind" => "PlanYear",
          "event_object_id" => model_instance.id.to_s
      } }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.publish!
      end

      context "when notice event received" do

        subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

        it "should return correct data model" do
          expect(merge_model).to be_a(recipient.constantize)
        end

        it "should return employer legal name" do
          expect(merge_model.employer_name).to eq employer_profile.organization.legal_name
        end

        it "should return plan year start date" do
          expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
        end

        it "should return broker status" do
          expect(merge_model.broker_present?).to be_falsey
        end
      end
    end
  end
end
