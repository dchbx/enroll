require 'rails_helper'

describe 'ModelEvents::BrokerHiredConfirmationToEmployer', :dbclean => :after_each do
  let(:model_event)  { "broker_hired_confirmation_to_employer" }
  let(:notice_event) { "broker_hired_confirmation_to_employer" }
  let!(:broker_agency_profile) { create :broker_agency_profile }
  let!(:broker_agency_account) { create :broker_agency_account,is_active: true, broker_agency_profile: broker_agency_profile }
  let!(:broker) { create :broker, broker_agency_profile: broker_agency_profile  }
  let!(:model_instance) { create(:employer_profile, broker_agency_accounts:[broker_agency_account])}

  describe "ModelEvent" do
    context "when ER hires a broker" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:employer_profile_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :broker_hired_confirmation_to_employer, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.trigger_model_event(:broker_hired_confirmation_to_employer)
      end
    end
  end

  describe "NoticeTrigger" do
    context "when ER hires a broker" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:broker_hired_confirmation_to_employer, model_instance, {}) }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.broker_hired_confirmation_to_employer"
          expect(payload[:event_object_kind]).to eq 'EmployerProfile'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.employer_profile_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.broker.primary_first_name",
        "employer_profile.broker.primary_last_name",
        "employer_profile.broker.assignment_date",
        "employer_profile.broker.primary_first_name",
        "employer_profile.broker.organization"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "EmployerProfile",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(model_instance)
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

    it "should return broker first name" do
      expect(merge_model.broker.primary_first_name).to eq broker_agency_account.writing_agent.parent.first_name
    end

    it "should return broker last name " do
      expect(merge_model.broker.primary_last_name).to eq broker_agency_account.writing_agent.parent.last_name
    end

    it "should return broker assignment date" do
      expect(merge_model.broker.assignment_date).to eq broker_agency_account.start_on
    end

    it "should return broker agency name " do
      expect(merge_model.broker.organization).to eq broker_agency_profile.legal_name
    end
  end
end

