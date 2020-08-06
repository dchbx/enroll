# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::GeneralAgencyFiredNotice', dbclean: :around_each  do

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
  let(:general_agency_account) { plan_design_organization.general_agency_accounts.create(general_agency_profile: general_agency_profile, start_on: start_on, aasm_state: 'active', broker_role_id: broker_agency_profile.primary_broker_role.id) }

  describe "when a GA is fired" do

    context "ModelEvent" do

      context "employer fires a broker and broker has default GA assigned" do

        before do
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
        end

        def fire_broker
          general_agency_account.update_attributes(aasm_state: 'inactive', end_on: start_on)
          general_agency_account.save!
        end

        it "should trigger notice" do
          general_agency_account.class.observer_peers.each_key do |observer|
            expect(observer).to receive(:process_ga_account_events) do |_instance, model_event|
              expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_fired, :klass_instance => general_agency_account, :options => {})
            end
          end
          fire_broker
        end
      end

      context "employer changes broker and broker has default GA assigned" do

        before do
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
        end

        def fire_broker
          general_agency_account.update_attributes(aasm_state: 'inactive', end_on: start_on)
          general_agency_account.save!
        end

        it "should trigger notice" do
          general_agency_account.class.observer_peers.each_key do |observer|
            expect(observer).to receive(:process_ga_account_events) do |_instance, model_event|
              expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_fired, :klass_instance => general_agency_account, :options => {})
            end
          end
          fire_broker
        end
      end

      context "broker removes GA for an employer" do

        def fire_broker
          broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
          general_agency_account.update_attributes(aasm_state: 'inactive', end_on: start_on)
          general_agency_account.save!
        end

        it "should trigger notice" do
          general_agency_account.class.observer_peers.each_key do |observer|
            expect(observer).to receive(:process_ga_account_events) do |_instance, model_event|
              expect(model_event).to be_an_instance_of(BenefitSponsors::ModelEvents::ModelEvent)
              expect(model_event).to have_attributes(:event_key => :general_agency_fired, :klass_instance => general_agency_account, :options => {})
            end
          end
          fire_broker
        end
      end
    end

    context "NoticeTrigger" do

      context 'when general agency account is the event object' do
        let(:subject)     { BenefitSponsors::Observers::NoticeObserver.new }
        let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:general_agency_fired, general_agency_account, {}) }

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.general_agency.general_agency_fired_confirmation_to_agency"
            expect(payload[:event_object_kind]).to eq "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile"
            expect(payload[:event_object_id]).to eq employer_profile.id.to_s
          end
          subject.process_ga_account_events(general_agency_account, model_event)
        end
      end
    end
  end

  describe "NoticeBuilder" do

    before do
      broker_agency_profile.update_attributes(default_general_agency_profile_id: general_agency_profile.id)
      broker_agency_profile.primary_broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id)
    end

    let(:broker_role) { broker_agency_profile.primary_broker_role }
    let!(:employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let(:data_elements) do
      [
        'general_agency.notice_date',
        'general_agency.employer_name',
        'general_agency.first_name',
        'general_agency.last_name',
        'general_agency.assignment_date',
        'general_agency.termination_date',
        'general_agency.legal_name',
        'general_agency.broker.primary_first_name',
        'general_agency.broker.primary_last_name',
        'general_agency.employer_poc_firstname',
        'general_agency.employer_poc_lastname'
    ]
    end

    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::GeneralAgency" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    context "when event is triggered with general_agency_account update" do

      let(:payload) do
        {
          "event_object_kind" => "BenefitSponsors::Organizations::AcaShop#{Settings.site.key.capitalize}EmployerProfile",
          "event_object_id" => employer_profile.id.to_s,
          "notice_params" => { "general_agency_account_id" => general_agency_account.id.to_s }
        }
      end

      before do
        general_agency_account.update_attributes(broker_role_id: broker_role.id)
        allow(subject).to receive(:resource).and_return(general_agency_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it 'should return merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return notice date' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it 'should return general agency legal name' do
        expect(merge_model.legal_name).to eq general_agency_profile.legal_name
      end

      it 'should return general agency - employer assignment date' do
        expect(merge_model.assignment_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it 'should return general agency - employer termination_date date' do
        expect(merge_model.termination_date).to eq start_on.strftime('%m/%d/%Y')
      end

      it 'should return employer poc first name' do
        expect(merge_model.employer_poc_firstname).to eq employer_staff_role.person.first_name
      end

      it 'should return employer poc last name' do
        expect(merge_model.employer_poc_lastname).to eq employer_staff_role.person.last_name
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