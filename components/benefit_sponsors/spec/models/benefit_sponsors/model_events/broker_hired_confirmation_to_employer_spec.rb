require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::BrokerHiredConfirmationToEmployer', :dbclean => :after_each do
  let(:notice_event)  { "broker_hired_confirmation_to_employer" }

  let!(:person) { create :person }
  let(:user)    { FactoryGirl.create(:user, :person => person)}
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

  let!(:person1) { FactoryGirl.create(:person) }
  let!(:broker_agency_organization1) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site) }
  let!(:broker_agency_profile) { broker_agency_organization1.broker_agency_profile}
  let!(:broker_agency_account) { create :benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, benefit_sponsorship: benefit_sponsorship }
  let!(:broker_role) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person1) }

  describe "NoticeTrigger" do
    context "when ER hires a broker" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.broker_hired_confirmation_to_employer"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end
        subject.deliver(recipient: employer_profile, event_object: employer_profile, notice_event: notice_event)
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
        "event_object_kind" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
        "event_object_id" => employer_profile.id
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

