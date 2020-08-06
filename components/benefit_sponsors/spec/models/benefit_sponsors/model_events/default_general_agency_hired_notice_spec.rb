# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::DefaultGeneralAgencyHiredNotice', dbclean: :around_each  do

  let(:start_on) { TimeKeeper.date_of_record }
  let(:person) { FactoryBot.create(:person) }
  let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
  let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
  let(:employer_profile)    { organization.employer_profile }
  let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

  let(:broker_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
  let(:broker_agency_profile)  { broker_agency.broker_agency_profile }

  let(:broker_agency_old) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
  let(:broker_agency_profile_old)  { broker_agency.broker_agency_profile }

  let(:general_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site)}
  let(:general_agency_profile) {general_agency.profiles.first }

  let(:broker_model_instance)          { broker_agency_profile }
  let(:broker_agency_account) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, employer_profile: employer_profile, broker_agency_profile: broker_agency_profile, is_active: true) }

  let(:plan_design_organization) { FactoryBot.create(:sponsored_benefits_plan_design_organization, sponsor_profile_id: employer_profile.id) }
  let(:ga_model_instance) { plan_design_organization.general_agency_accounts.build(general_agency_profile: general_agency_profile, start_on: start_on, broker_role_id: broker_agency_profile.primary_broker_role.id) }


  context 'ModelEvent' do

    def update_broker_agency_profile
      broker_agency_profile.default_general_agency_profile = general_agency_profile
      broker_agency_profile.save
    end

    context 'broker has a default GA and selects another GA as default' do

      let(:general_agency2) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site)}
      let(:general_agency_profile2) {general_agency2.profiles.first }

      before do
        broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile2.id)
      end

      it 'should trigger notice' do
        broker_agency_profile.class.observer_peers.each_key do |observer|
          expect(observer).to receive(:process_broker_agency_profile_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :default_general_agency_hired, :klass_instance => broker_agency_profile, :options => { :old_general_agency_profile_id => general_agency_profile2.id.to_s })
          end
        end
        broker_agency_profile.class.observer_peers.each_key do |observer|
          expect(observer).to receive(:process_broker_agency_profile_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :default_general_agency_fired, :klass_instance => broker_agency_profile, :options => { :old_general_agency_profile_id => general_agency_profile2.id.to_s })
          end
        end
        update_broker_agency_profile
      end
    end

    context 'broker selects GA as default' do

      it 'should trigger notice' do
        broker_agency_profile.class.observer_peers.each_key do |observer|
          expect(observer).to receive(:process_broker_agency_profile_events) do |_instance, model_event|
            expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :default_general_agency_hired, :klass_instance => broker_agency_profile)
          end
        end
        update_broker_agency_profile
      end
    end

    context 'NoticeTrigger' do
      context 'when broker_agency_profile is the event object' do

        before do
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
        end

        let(:subject)     { BenefitSponsors::Observers::NoticeObserver.new }
        let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:default_general_agency_hired, broker_model_instance, {}) }

        it 'should trigger notice event' do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq 'acapi.info.events.general_agency.default_ga_hired_notice_to_general_agency'
            expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::BrokerAgencyProfile'
            expect(payload[:event_object_id]).to eq broker_agency_profile.id.to_s
          end
          subject.process_broker_agency_profile_events(broker_agency_profile, model_event)
        end
      end
    end
  end

  describe 'NoticeBuilder' do

    before do
      broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
      broker_agency_profile.primary_broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id)
      ga_model_instance.save
    end

    let(:broker_role) { broker_agency_profile.primary_broker_role }
    let!(:employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}

    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { 'Notifier::MergeDataModels::GeneralAgency' }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    context 'when event is triggered with broker_agency_profile as event_object' do

      let(:data_elements) do
        [
          'general_agency.notice_date',
          'general_agency.first_name',
          'general_agency.last_name',
          'general_agency.assignment_date',
          'general_agency.legal_name',
          'general_agency.broker.primary_first_name',
          'general_agency.broker.primary_last_name'
        ]
      end

      let(:payload) do
        {
          'event_object_kind' => 'BenefitSponsors::Organizations::BrokerAgencyProfile',
          'event_object_id' => broker_agency_profile.id.to_s
        }
      end

      before do
        allow(subject).to receive(:resource).and_return(general_agency_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should return merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return notice date' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return general agency legal name' do
        expect(merge_model.legal_name).to eq general_agency_profile.legal_name
      end

      it 'should return general agency - broker assignment date' do
        expect(merge_model.assignment_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it 'should return broker first name ' do
        expect(merge_model.broker.primary_first_name).to eq broker_role.person.first_name
      end

      it 'should return broker last name ' do
        expect(merge_model.broker.primary_last_name).to eq broker_role.person.last_name
      end
    end
  end
end