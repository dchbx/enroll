# frozen_string_literal: true

require "rails_helper"

module Operations
  module SecureMessages
    RSpec.describe Create do

      subject do
        described_class.new.call(params)
      end

      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
      let(:employer_profile) {organization.employer_profile}

      let(:general_agency_person) { FactoryBot.create :person }
      let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, person: general_agency_person, is_primary: true)}
      let(:general_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_general_agency_profile, organization: organization) }

      let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
      let(:broker_person) { broker_agency_profile.primary_broker_role.person }

      describe 'given empty resource' do
        let(:params) {{resource: nil, message_params: {subject: 'test', body: 'test'}, document: nil}}
        let(:error_message) {{:message => ['Please find valid resource to send the message']}}

        it 'fails' do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe "given empty :subject" do

        let(:params) { {resource: employer_profile,  message_params: {subject: '', body: 'test'}, document: nil }}
        let(:error_message) {{:subject => ['Please enter subject']}}


        it "fails" do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe "given empty :body" do

        let(:params) { { resource: employer_profile, message_params: {subject: 'test', body: '' }, document: nil}}
        let(:error_message) {{:body => ['Please enter content']}}


        it "fails" do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe "given empty :body and :subject" do

        let(:params) { { resource: employer_profile, message_params: {subject: '', body: ''}, document: nil}}
        let(:error_message) {{:subject => ['Please enter subject'], :body => ['Please enter content']}}


        it "fails" do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe "not passing keys :body and :subject" do

        let(:params) { {} }
        let(:error_message) {{:subject => ['is missing'], :body => ['is missing']}}


        it "fails" do
          result = Operations::SecureMessages::Create.new.validate_message_payload(params)
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "passing valid employer data" do

        let(:params) { { resource: employer_profile, message_params: {subject: 'test', body: 'test'}, document: nil}}

        it "success" do
          expect(subject).to be_success
          expect(subject.success).to eq employer_profile
          expect(employer_profile.inbox.messages.where(subject: 'test').first).to be_present
        end
      end

      describe "passing valid broker agency data" do

        let(:params) { { resource: broker_agency_profile, message_params: {subject: 'test', body: 'test'}, document: nil}}

        it "success" do
          expect(subject).to be_success
          expect(subject.success).to eq broker_person
          expect(broker_person.inbox.messages.where(subject: 'test').first).to be_present
        end
      end

      describe "passing valid general agency data" do

        let(:params) { { resource: general_agency_profile, message_params: {subject: 'test', body: 'test'}, document: nil}}

        it "success" do
          expect(subject).to be_success
          expect(subject.success).to eq general_agency_profile
          expect(general_agency_profile.inbox.messages.where(subject: 'test').first).to be_present
        end
      end
    end
  end
end
