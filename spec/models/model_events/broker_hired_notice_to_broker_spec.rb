require 'rails_helper'

describe 'ModelEvents::BrokerHiredNoticeToBroker', dbclean: :around_each  do
  let(:model_event)  { "broker_hired_notice_to_broker" }
  let(:notice_event) { "broker_hired_notice_to_broker" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:broker_agency_account) { create :broker_agency_account,is_active: true, broker_agency_profile: broker_agency_profile }
  let(:organization) { FactoryGirl.create(:organization) }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }
  let!(:model_instance) { create(:employer_profile,legal_name:"ffff",broker_agency_accounts:[broker_agency_account])}
  let(:person){ create :person}


  before do
    broker_agency_profile.primary_broker_role.update_attributes!(:broker_agency_profile_id => broker_agency_profile.id)
  end
 
  describe "NoticeTrigger" do
    context "when ER successfully hires a broker" do
      subject { Observers::NoticeObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker.broker_hired_notice_to_broker"
          expect(payload[:event_object_kind]).to eq 'EmployerProfile'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.deliver(recipient: broker_agency_profile.primary_broker_role, event_object: model_instance, notice_event: "broker_hired_notice_to_broker")
      end
    end
  end

   describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "broker_profile.notice_date",
          "broker_profile.employer_name",
          "broker_profile.first_name",
          "broker_profile.last_name",
          "broker_profile.assignment_date",
          "broker_profile.broker_agency_name",
          "broker_profile.employer_poc_firstname",
          "broker_profile.employer_poc_lastname"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::BrokerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "EmployerProfile",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:broker_person) { broker_agency_profile.primary_broker_role.person }

    before do
      allow(subject).to receive(:resource).and_return(broker_agency_profile.primary_broker_role)
      allow(subject).to receive(:payload).and_return(payload)
      allow(Person).to receive(:staff_for_employer).with(model_instance).and_return([person])
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

    it "should return broker first name " do
      expect(merge_model.first_name).to eq broker_person.first_name
    end

    it "should return broker last name " do
      expect(merge_model.last_name).to eq broker_person.last_name
    end

    it "should return broker assignment date" do
      expect(merge_model.assignment_date).to eq broker_agency_account.start_on.strftime('%m/%d/%Y')
    end

    it "should return employer poc first name" do
      expect(merge_model.employer_poc_firstname).to eq model_instance.staff_roles.first.first_name
    end

    it "should return employer poc last name" do
      expect(merge_model.employer_poc_lastname).to eq model_instance.staff_roles.first.last_name
    end

    it "should return broker agency name " do
      expect(merge_model.broker_agency_name).to eq broker_agency_profile.legal_name
    end

  end
end