require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::BrokerAgencyHiredConfirmation', dbclean: :around_each  do
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
  let!(:broker_role1) { broker_agency_profile.primary_broker_role }
  
  before do
    broker_agency_profile.update_attributes(primary_broker_role_id: broker_role1.id)
  end

  describe "when ER successfully hires a broker" do
    let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:broker_hired, model_instance, {}) }
    subject { BenefitSponsors::Observers::NoticeObserver.new }

    context "ModelEvent" do
      it "should trigger model event" do
        allow(subject).to receive(:process_broker_agency_events).and_return(model_instance, model_event)
        expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
        expect(model_event).to have_attributes(:event_key => :broker_hired, :klass_instance => model_instance, :options => {})
        model_instance.save!
      end
    end

    context "NoticeTrigger" do
      it "should trigger notice event" do

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker.broker_hired_notice_to_broker"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker_agency.broker_agency_hired_confirmation"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end
        
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.broker_hired_confirmation_to_employer"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq employer_profile.id.to_s
        end

        subject.process_broker_agency_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do
     
    context "when broker_hired_notice_to_broker is triggered" do
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
          "event_object_kind" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
          "event_object_id" => employer_profile.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(broker_agency_profile.primary_broker_role)
        allow(subject).to receive(:payload).and_return(payload)
        person.employer_staff_roles.create! benefit_sponsor_employer_profile_id: employer_profile.id
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

      it "should return broker first name " do
        expect(merge_model.first_name).to eq broker_role1.person.first_name
      end

      it "should return broker last name " do
        expect(merge_model.last_name).to eq broker_role1.person.last_name
      end

      it "should return broker assignment date" do
        expect(merge_model.assignment_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return employer poc first name" do
        expect(merge_model.employer_poc_firstname).to eq employer_profile.staff_roles.first.first_name
      end

      it "should return employer poc last name" do
        expect(merge_model.employer_poc_lastname).to eq employer_profile.staff_roles.first.last_name
      end

      it "should return broker agency name " do
        expect(merge_model.broker_agency_name).to eq broker_agency_profile.legal_name
      end
    end 


    context "when broker_agency_hired_confirmation is triggered" do
      let(:data_elements) {
        [
          "broker_agency_profile.notice_date",
          "broker_agency_profile.employer_name",
          "broker_agency_profile.first_name",
          "broker_agency_profile.last_name",
          "broker_agency_profile.assignment_date",
          "broker_agency_profile.broker_agency_name",
          "broker_agency_profile.employer_poc_firstname",
          "broker_agency_profile.employer_poc_lastname",
          "broker_agency_profile.employer_poc_phone",
          "broker_agency_profile.employer_poc_email"
        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::BrokerAgencyProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
          "event_object_id" => employer_profile.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(broker_agency_profile)
        allow(subject).to receive(:payload).and_return(payload)
        broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role1.id)
        person.employer_staff_roles.create! benefit_sponsor_employer_profile_id: employer_profile.id
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

      it "should return broker first and last name" do
        expect(merge_model.first_name).to eq broker_agency_profile.primary_broker_role.person.first_name
        expect(merge_model.last_name).to eq broker_agency_profile.primary_broker_role.person.last_name
      end

      it "should return broker assignment date" do
        expect(merge_model.assignment_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return employer poc name" do
        expect(merge_model.employer_poc_firstname).to eq employer_profile.staff_roles.first.first_name
        expect(merge_model.employer_poc_lastname).to eq employer_profile.staff_roles.first.last_name
      end

      it "should return employer poc phone" do
        expect(merge_model.employer_poc_phone).to eq employer_profile.staff_roles.first.work_phone_or_best
      end

      it "should return employer poc email" do
        expect(merge_model.employer_poc_email).to eq employer_profile.staff_roles.first.work_email_or_best
      end

      it "should return broker agency name " do
        expect(merge_model.broker_agency_name).to eq broker_agency_profile.legal_name
      end
    end 
    
    context "when broker_agency_hired_confirmation is triggered" do
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
        expect(merge_model.broker.primary_first_name).to eq model_instance.writing_agent.parent.first_name
      end

      it "should return broker last name " do
        expect(merge_model.broker.primary_last_name).to eq model_instance.writing_agent.parent.last_name
      end

      it "should return broker assignment date" do
        expect(merge_model.broker.assignment_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return broker agency name " do
        expect(merge_model.broker.organization).to eq broker_agency_profile.legal_name
      end
    end
  end
end
