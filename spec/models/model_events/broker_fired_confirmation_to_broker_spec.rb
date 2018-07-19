require 'rails_helper'

describe 'ModelEvents::BrokerFiredConfirmationToBroker', :dbclean => :after_each do
  let(:model_event)  { "broker_fired_confirmation_to_broker" }	
  let(:notice_event) { "broker_fired_confirmation_to_broker" }
  let!(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }
  let!(:broker_agency_account) { create :broker_agency_account,is_active: true, broker_agency_profile: broker_agency_profile }
  let!(:employer_profile) { create(:employer_profile, broker_agency_accounts:[broker_agency_account])}
  let(:end_on) {TimeKeeper.date_of_record}

  before do
    employer_profile.fire_broker_agency
    employer_profile.save!
    @broker_agency_account1 = employer_profile.broker_agency_accounts.unscoped.select{|br| br.is_active ==  false}.sort_by(&:created_at).last
  end

  describe "NoticeTrigger" do
    context "when ER fires a broker" do
      subject { Observers::NoticeObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker.broker_fired_confirmation_to_broker"
          expect(payload[:event_object_kind]).to eq 'EmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end
        subject.deliver(recipient: broker_agency_account.broker_agency_profile.primary_broker_role, event_object: employer_profile, notice_event: "broker_fired_confirmation_to_broker")
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
        "broker_profile.termination_date",
        "broker_profile.broker_agency_name"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::BrokerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "EmployerProfile",
        "event_object_id" => employer_profile.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:broker_role) { broker_agency_account.broker_agency_profile.primary_broker_role }

    before do
      allow(subject).to receive(:resource).and_return(broker_role)
      allow(subject).to receive(:payload).and_return(payload)
      broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id )
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return broker first name" do
      expect(merge_model.first_name).to eq broker_agency_profile.primary_broker_role.person.first_name
    end

    it "should return broker last name " do
      expect(merge_model.last_name).to eq broker_agency_profile.primary_broker_role.person.last_name
    end

    it "should return broker termination date" do
      expect(merge_model.termination_date).to eq @broker_agency_account1.end_on
    end

    it "should set broker is_active to false" do
      expect(@broker_agency_account1.is_active).to be_falsey
    end

    it "should return broker agency name " do
      expect(merge_model.broker_agency_name).to eq broker_agency_profile.legal_name
    end
  end
end

