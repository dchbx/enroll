# frozen_string_literal: true

require "rails_helper"

module Operations
  module Documents
    RSpec.describe Upload do

      subject do
        described_class.new.call(params)
      end

      let(:tempfile) do
        tf = Tempfile.new('test.pdf')
        tf.write("DATA GOES HERE")
        tf.rewind
        tf
      end

      let(:user)             { FactoryBot.create(:user) }
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
      let(:employer_profile) {organization.employer_profile}
      let(:doc_storage) do
        {:title => 'untitled',
         :language => 'en',
         :format => 'application/octet-stream',
         :source => 'enroll_system',
         :document_type => 'notice',
         :subjects => [{:id => BSON::ObjectId.new.to_s, :type => 'test'}],
         :id => BSON::ObjectId.new.to_s,
         :extension => 'pdf' }
      end

      describe 'given empty resource' do
        let(:params) {{resource: nil, file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")}, user: user}}
        let(:error_message) {{:message => ['Please find valid resource to create document.']}}

        it 'fails' do
          expect(subject).not_to be_success
          expect(subject.failure).to eq error_message
        end
      end

      describe "when response has empty subjects" do
        let(:params) do
          {resource: employer_profile,
           file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")}, user: user }
        end
        let(:error_message) do
          {:subjects => ['Missing attributes for subjects']}
        end

        it "fails" do
          doc_storage[:subjects] = []
          result = Operations::Documents::Upload.new.validate_response(doc_storage.transform_keys(&:to_sym))
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "when response has empty id" do
        let(:params) do
          {resource: employer_profile,
           file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
           user: user }
        end
        let(:error_message) do
          {:id => ['Doc storage Identifier is blank']}
        end

        it "fails" do
          doc_storage[:id] = ""
          result = Operations::Documents::Upload.new.validate_response(doc_storage.transform_keys(&:to_sym))
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "when response has empty type" do
        let(:params) do
          {resource: employer_profile,
           file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
           user: user }
        end
        let(:error_message) {{:document_type => ['Document type is missing']}}

        it "fails" do
          doc_storage[:document_type] = ""
          result = Operations::Documents::Upload.new.validate_response(doc_storage.transform_keys(&:to_sym))
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "when response has empty source" do
        let(:params) do
          {resource: employer_profile,
           file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
           user: user }
        end
        let(:error_message) do
          {:source => ['Invalid source']}
        end

        it "fails" do
          doc_storage[:source] = ""
          result = Operations::Documents::Upload.new.validate_response(doc_storage.transform_keys(&:to_sym))
          expect(result).not_to be_success
          expect(result.failure).to eq error_message
        end
      end

      describe "passing valid data" do
        let(:params) do
          {resource: employer_profile,
           file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
           user: user }
        end
        it "success" do
          validated_params = Operations::Documents::Upload.new.validate_response(doc_storage.transform_keys(&:to_sym))
          file = Operations::Documents::Upload.new.create_document(employer_profile, params[:file_params], validated_params.value!)
          expect(file.success?).to eq true
        end

        it "should save document ot profile" do
          validated_params = Operations::Documents::Upload.new.validate_response(doc_storage.transform_keys(&:to_sym))
          Operations::Documents::Upload.new.create_document(employer_profile, params[:file_params], validated_params.value!)
          expect(employer_profile.documents.count).to eq 1
        end
      end

      describe "passing valid broker agency data" do
        let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }
        let(:broker_person) { broker_agency_profile.primary_broker_role.person }
        let(:general_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_general_agency_profile, organization: organization) }
        let(:params) do
          {resource: broker_agency_profile,
           file_params: {subject: 'test', body: 'test', file: Rack::Test::UploadedFile.new(tempfile, "application/pdf")},
           user: user }
        end
        it "success" do
          validated_params = Operations::Documents::Upload.new.validate_response(doc_storage.transform_keys(&:to_sym))
          file = Operations::Documents::Upload.new.create_document(broker_person, params[:file_params], validated_params.value!)
          expect(file.success?).to eq true
        end

        it "should save document ot profile" do
          validated_params = Operations::Documents::Upload.new.validate_response(doc_storage.transform_keys(&:to_sym))
          Operations::Documents::Upload.new.create_document(broker_person, params[:file_params], validated_params.value!)
          expect(broker_person.documents.count).to eq 1
        end
      end
    end
  end
end
