require 'rails_helper'

describe 'ModelEvents::BrokerFiredConfirmationToEmployer', :dbclean => :after_each do
  let(:notice_event) { "broker_fired_confirmation_to_employer" }
  let!(:broker_agency_profile) { create :broker_agency_profile }
  let!(:broker_agency_account) { create :broker_agency_account,is_active: true, broker_agency_profile: broker_agency_profile }
  let!(:broker) { create :broker, broker_agency_profile: broker_agency_profile  }
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
          expect(event_name).to eq "acapi.info.events.employer.broker_fired_confirmation_to_employer"
          expect(payload[:event_object_kind]).to eq 'BrokerAgencyAccount'
          expect(payload[:event_object_id]).to eq broker_agency_account.id.to_s
        end
        subject.deliver(recipient: employer_profile, event_object: broker_agency_account, notice_event: "broker_fired_confirmation_to_employer")
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
        "employer_profile.broker.termination_date",
        "employer_profile.broker.primary_first_name",
        "employer_profile.broker.organization"
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "BrokerAgencyAccount",
        "event_object_id" => broker_agency_account.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employer_profile)
      allow(subject).to receive(:payload).and_return(payload)
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
      expect(merge_model.broker.primary_first_name).to eq @broker_agency_account1.writing_agent.parent.first_name
    end

    it "should return broker last name " do
      expect(merge_model.broker.primary_last_name).to eq @broker_agency_account1.writing_agent.parent.last_name
    end

    it "should return broker termination date" do
      expect(merge_model.broker.termination_date).to eq @broker_agency_account1.end_on
    end

    it "should set broker is_active to false" do
      expect(@broker_agency_account1.is_active).to be_falsey
    end

    it "should return broker agency name " do
      expect(merge_model.broker.organization).to eq broker_agency_profile.legal_name
    end
  end
end
