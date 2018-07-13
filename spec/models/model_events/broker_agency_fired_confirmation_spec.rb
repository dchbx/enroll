require 'rails_helper'

describe 'ModelEvents::BrokerAgencyFiredConfirmation', dbclean: :around_each  do
  let(:model_event)  { "broker_agency_fired_confirmation" }
  let(:notice_event) { "broker_agency_fired_confirmation" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month}
  let!(:broker_agency_profile) { create :broker_agency_profile}
  let!(:broker_agency_account) { create :broker_agency_account, is_active: true, broker_agency_profile: broker_agency_profile }
  let!(:broker) { create :broker, broker_agency_profile: broker_agency_profile}
  let!(:person){ create :person }
  let!(:model_instance) { create(:employer_profile, legal_name:"agency1", broker_agency_accounts:[broker_agency_account])}
 
  describe "NoticeTrigger" do
    context "when ER successfully hires a broker" do
      subject { Observers::NoticeObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker_agency.broker_agency_fired_confirmation"
          expect(payload[:event_object_kind]).to eq 'EmployerProfile'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.deliver(recipient: broker_agency_profile, event_object: model_instance, notice_event: "broker_agency_fired_confirmation")
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "broker_agency_profile.notice_date",
          "broker_agency_profile.employer_name",
          "broker_agency_profile.first_name",
          "broker_agency_profile.last_name",
          "broker_agency_profile.assignment_date",
          "broker_agency_profile.termination_date",
          "broker_agency_profile.broker_agency_name",
          "broker_agency_profile.employer_poc_firstname",
          "broker_agency_profile.employer_poc_lastname"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::BrokerAgencyProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "EmployerProfile",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(broker_agency_profile)
      allow(subject).to receive(:payload).and_return(payload)
      allow(Person).to receive(:staff_for_employer).with(model_instance).and_return([person])
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq model_instance.legal_name
    end

    it "should return broker first and last name" do
      expect(merge_model.first_name).to eq broker_agency_profile.primary_broker_role.person.first_name
      expect(merge_model.last_name).to eq broker_agency_profile.primary_broker_role.person.last_name
    end

    it "should return broker assignment date" do
      expect(merge_model.assignment_date).to eq broker_agency_account.start_on.strftime('%m/%d/%Y')
    end

    it "should return broker termination date" do
      expect(merge_model.termination_date).to eq broker_agency_account.end_on
    end

    it "should return employer poc name" do
      expect(merge_model.employer_poc_firstname).to eq model_instance.staff_roles.first.first_name
      expect(merge_model.employer_poc_lastname).to eq model_instance.staff_roles.first.last_name
    end

    it "should return broker agency name " do
      expect(merge_model.broker_agency_name).to eq broker_agency_profile.legal_name
    end

  end
end
