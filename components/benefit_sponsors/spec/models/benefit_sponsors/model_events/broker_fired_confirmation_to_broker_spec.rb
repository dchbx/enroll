require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::BrokerFiredConfirmationToBroker', :dbclean => :after_each do
  let(:notice_event) { "broker_fired_confirmation_to_broker" }
  let(:end_on) {TimeKeeper.date_of_record}

  let!(:person) { create :person }
  let(:user)    { FactoryGirl.create(:user, :person => person)}
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:model_instance)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { model_instance.add_benefit_sponsorship }

  let!(:person1) { FactoryGirl.create(:person) }
  let!(:broker_agency_organization1) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site) }
  let!(:broker_agency_profile) { broker_agency_organization1.broker_agency_profile}
  let!(:broker_agency_account) { create :benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, benefit_sponsorship: benefit_sponsorship }
  let!(:broker_role) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person1) }

  before do
    model_instance.fire_broker_agency
    model_instance.save!
    @broker_agency_account1 = model_instance.broker_agency_accounts.unscoped.select{|br| br.is_active ==  false}.sort_by(&:created_at).last
  end

  describe "NoticeTrigger" do
    context "when ER fires a broker" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker.broker_fired_confirmation_to_broker"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.deliver(recipient: broker_role, event_object: model_instance, notice_event: notice_event)
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
        "event_object_kind" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

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
      expect(merge_model.employer_name).to eq model_instance.legal_name
    end

    it "should return broker first name" do
      expect(merge_model.first_name).to eq broker_role.person.first_name
    end

    it "should return broker last name " do
      expect(merge_model.last_name).to eq broker_role.person.last_name
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

