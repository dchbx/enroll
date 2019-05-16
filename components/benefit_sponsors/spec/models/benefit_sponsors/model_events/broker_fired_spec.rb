require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::BrokerFired', :dbclean => :after_each do
  let(:end_on) {TimeKeeper.date_of_record}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month}

  let!(:person) { create :person }
  let(:user)    { FactoryBot.create(:user, :person => person)}
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

  let!(:person1) { FactoryBot.create(:person) }
  let!(:broker_agency_organization1) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site) }
  let!(:broker_agency_profile) { broker_agency_organization1.broker_agency_profile}
  let!(:model_instance) { create :benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, benefit_sponsorship: benefit_sponsorship }
  let!(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person1) }

  before do
    employer_profile.fire_broker_agency
    employer_profile.save!
    broker_agency_profile.update_attributes(primary_broker_role_id: broker_role.id)
    @broker_agency_account1 = employer_profile.broker_agency_accounts.unscoped.select{|br| br.is_active ==  false}.sort_by(&:created_at).last
  end

  describe "when ER fires a broker" do
    let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:broker_fired, model_instance, {}) }
    subject { BenefitSponsors::Observers::NoticeObserver.new }

    context "ModelEvent" do
      it "should trigger model event" do
        allow(subject).to receive(:process_broker_agency_events).and_return(model_instance, model_event)
        expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
        expect(model_event).to have_attributes(:event_key => :broker_fired, :klass_instance => model_instance, :options => {})
        model_instance.save!
      end
    end

    context "NoticeTrigger" do
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker.broker_fired_confirmation_to_broker"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker_agency.broker_agency_fired_confirmation"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.broker_fired_confirmation_to_employer"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Accounts::BrokerAgencyAccount'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.process_broker_agency_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    context "when broker_fired_confirmation_to_employer is triggered" do 
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
      let(:payload)   { {
          "event_object_kind" => "BenefitSponsors::Accounts::BrokerAgencyAccount",
          "event_object_id" => model_instance.id
      } }
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
        expect(merge_model.broker.termination_date).to eq @broker_agency_account1.end_on.strftime('%m/%d/%Y')
      end

      it "should set broker is_active to false" do
        expect(@broker_agency_account1.is_active).to be_falsey
      end

      it "should return broker agency name " do
        expect(merge_model.broker.organization).to eq broker_agency_profile.legal_name
      end
    end

    context "when broker_agency_fired_confirmation is triggered" do 
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
      let(:payload)   { {
          "event_object_kind" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
          "event_object_id" => employer_profile.id
      } }

      before do
        allow(subject).to receive(:resource).and_return(broker_role)
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

    context "when broker_fired_confirmation_to_broker is triggered" do
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
      let(:payload)   { {
          "event_object_kind" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
          "event_object_id" => employer_profile.id
      } }

      before do
        allow(subject).to receive(:resource).and_return(broker_agency_profile)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.update_attributes(start_on: start_on)
        person.employer_staff_roles.create! benefit_sponsor_employer_profile_id: employer_profile.id
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime("%m/%d/%Y")
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return broker first and last name" do
        expect(merge_model.first_name).to eq broker_agency_profile.primary_broker_role.person.first_name
        expect(merge_model.last_name).to eq broker_agency_profile.primary_broker_role.person.last_name
      end

      it "should return broker termination date" do
        expect(merge_model.termination_date).to eq @broker_agency_account1.end_on.strftime("%m/%d/%Y")
      end

      it "should return employer poc name" do
        expect(merge_model.employer_poc_firstname).to eq employer_profile.staff_roles.first.first_name
        expect(merge_model.employer_poc_lastname).to eq employer_profile.staff_roles.first.last_name
      end

      it "should return broker agency name " do
        expect(merge_model.broker_agency_name).to eq broker_agency_profile.legal_name
      end
    end
  end
end
