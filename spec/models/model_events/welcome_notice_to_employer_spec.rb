require 'rails_helper'

describe 'ModelEvents::WelcomeNoticeToEmployer', dbclean: :around_each  do
  let(:model_event)  { "welcome_notice_to_employer" }
  let(:notice_event) { "welcome_notice_to_employer" }
  let!(:model_instance) { create(:employer_profile)}
  let(:person){ create :person}
 
  describe "ModelEvent" do
    context "when ER successfully creates account" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:employer_profile_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :welcome_notice_to_employer, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.trigger_model_event(:welcome_notice_to_employer)
      end
    end
  end

  describe "NoticeTrigger" do
    context "when ER successfully creates account" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:welcome_notice_to_employer, model_instance, {}) }
      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.welcome_notice_to_employer"
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
          "employer_profile.employer_name"
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
  end
end
