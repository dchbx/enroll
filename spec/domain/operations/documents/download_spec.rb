# frozen_string_literal: true

require "rails_helper"

module Operations
  module Documents
    RSpec.describe Download do

      subject do
        described_class.new.call(params)
      end

      let(:user)             { FactoryBot.create(:user) }
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site)}
      let(:employer_profile) {organization.employer_profile}

      before do
        document = employer_profile.documents.build(doc_identifier: BSON::ObjectId.new.to_s, creator: "hbx_staff", title: "file_name_1")
        document.save!
      end

      describe 'given empty user' do
        let(:params) {{params: {}, user: nil}}
        let(:error_message) {{:message => "Please login to download the document"}}

        it 'fails' do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe 'given empty params' do
        let(:params) {{params: {}, user: user}}
        let(:error_message) {{:model => ["is missing"], :model_id => ["is missing"], :relation => ["is missing"], :relation_id => ["is missing"]}}

        it 'fails' do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe 'pass params with invalid type' do
        let(:params) {{params: {:model => 1234, :model_id => true, :relation => true, :relation_id => 1234}, user: user}}
        let(:error_message) {{:model => ["must be a string"], :model_id => ["must be a string"], :relation => ["must be a string"], :relation_id => ["must be a string"]}}

        it 'fails' do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe 'pass params with invalid resource' do
        let(:params) {{params: {:model => employer_profile.class.to_s, :model_id => organization.id.to_s, :relation => "documents", :relation_id => employer_profile.documents.first.id.to_s}, user: user}}
        let(:error_message) {{ :message => ["Profile not found"]}}

        it 'fails' do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe 'pass params with valid resource' do
        let(:params) {{params: {:model => employer_profile.class.to_s, :model_id => employer_profile.id.to_s, :relation => "documents", :relation_id => employer_profile.documents.first.id.to_s}, user: user}}

        it 'should fail in dev and test env' do
          expect(subject).not_to be_success
        end
      end
    end
  end
end
