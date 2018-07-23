require "rails_helper"

module TransportGateway
  describe Adapters::S3Adapter, "#parse_s3_uri" do
    describe "given an s3 uri with no bucket" do
      let(:uri) { URI.parse("s3://region/") }

      it "raises an error" do
        expect{ subject.check_s3_uri(uri) }.to raise_error(URI::InvalidComponentError, /both bucket and file name must be provided/)
      end
    end

    describe "given an s3 uri with a bucket but no file name" do
      let(:uri) { URI.parse("s3://bucket@region") }

      it "raises an error" do
        expect{ subject.check_s3_uri(uri) }.to raise_error(URI::InvalidComponentError, /both bucket and file name must be provided/)
      end
    end

  end

  describe Adapters::S3Adapter, "#send_message" do
    let(:message) { ::TransportGateway::Message.new(to: to, from: from, body: body) }

    describe "given:
      - a nil body
      - no 'from'
      - a 'to'
    " do

      let(:body) { nil }
      let(:to) { URI.parse("file:///somewhere") }
      let(:from) { nil }

      before :each do
        subject.assign_providers(nil, nil)
      end

      it "raises an error" do
        expect{ subject.send_message(message) }.to raise_error(ArgumentError, /source data not provided/)
      end
    end

    describe "given:
      - a nil body
      - a 'from'
      - no 'to'
    " do

      let(:body) { nil }
      let(:to) { nil }
      let(:from) { URI.parse("file:///somewhere") }

      before :each do
        subject.assign_providers(nil, nil)
      end

      it "raises an error" do
        expect{ subject.send_message(message) }.to raise_error(ArgumentError, /destination not provided/)
      end
    end

    describe "given:
      - a content body
      - no 'from'
      - a 'to' that lacks a bucket/file name combination
    " do

      let(:body) { "SOME CONTENT HOMIE" }
      let(:to) { URI.parse("s3://bucket@service_endpoint") }
      let(:from) { nil }

      before :each do
        subject.assign_providers(nil, nil)
      end

      it "raises an error" do
        expect{ subject.send_message(message) }.to raise_error(URI::InvalidComponentError, /both bucket and file name must be provided/)
      end
    end

    describe "given:
      - a content body
      - no 'from'
      - a 'to' with a valid uri
      - a credential provider that doesn't have credentials for that uri
    " do

      let(:body) { "SOME CONTENT HOMIE" }
      let(:to) { URI.parse("s3://bucket@service_endpoint/file_name") }
      let(:from) { nil }
      let(:credential_provider) { double }

      before :each do
        allow(credential_provider).to receive(:credentials_for).with(to).and_return(nil)
        subject.assign_providers(nil, credential_provider)
      end

      it "raises an error" do
        expect { subject.send_message(message) }.to raise_error(ArgumentError, /credentials not found for uri/)
      end
    end

    describe "given:
      - a content body
      - no 'from'
      - a 'to' with a valid uri
      - a credential provider that has credentials for the uri
    " do

      let(:body) { "SOME CONTENT HOMIE" }
      let(:to) { URI.parse("s3://bucket@service_endpoint/file_name") }
      let(:from) { nil }
      let(:credential_provider) { double }
      let(:credentials) { double }
      let(:s3_credential_options) do
        {
          access_key_id: "ACCESS KEY",
          secret_access_key: "SECRET ACCESS KEY"
        }
      end

      let(:s3_client) do
        instance_double(Aws::S3::Client)
      end

      let(:s3_resource) do
        instance_double(Aws::S3::Resource)
      end

      let(:bucket) do
        instance_double(Aws::S3::Bucket)
      end

      before :each do
        allow(credential_provider).to receive(:credentials_for).with(to).and_return(credentials)
        allow(credentials).to receive(:s3_options).and_return(s3_credential_options)
        allow(Aws::S3::Client).to receive(:new).with({region: "service_endpoint"}.merge(s3_credential_options)).and_return(s3_client)
        allow(Aws::S3::Resource).to receive(:new).with({client: s3_client}).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).with("bucket").and_return(bucket)
        allow(bucket).to receive(:put_object).with({
          key: "file_name",
          content_length: body.bytesize,
          body: body
        })
        subject.assign_providers(nil, credential_provider)
      end

      it "creates the client with the credentials and connection info" do
        expected_information = {
           region: "service_endpoint"
        }.merge(s3_credential_options)
        expect(Aws::S3::Client).to receive(:new).with(expected_information).and_return(s3_client)
        subject.send_message(message)
      end

      it "uploads the body to the key" do
        expected_information = {
          key: "file_name",
          content_length: body.length,
          body: body
        }
        expect(bucket).to receive(:put_object).with(expected_information)
        subject.send_message(message)
      end
    end

    describe "given:
      - no body
      - a 'from'
      - a 'to' with a valid uri
      - a credential provider that has credentials for the uri
    " do

      let(:body) { nil }
      let(:to) { URI.parse("s3://bucket@service_endpoint/file_name") }
      let(:from) { URI.parse("file:///whatever_file_wherever") }
      let(:credential_provider) { double }
      let(:credentials) { double }
      let(:s3_credential_options) do
        {
          access_key_id: "ACCESS KEY",
          secret_access_key: "SECRET ACCESS KEY"
        }
      end

      let(:s3_client) do
        instance_double(Aws::S3::Client)
      end

      let(:s3_resource) do
        instance_double(Aws::S3::Resource)
      end

      let(:bucket) do
        instance_double(Aws::S3::Bucket)
      end

      let(:source_io_stream) { double }

      let(:source_stream) do
        double({
          :size => 300,
          :stream => source_io_stream 
        })
      end

      let(:gateway) do
        instance_double(TransportGateway::Gateway)
      end

      before :each do
        allow(credential_provider).to receive(:credentials_for).with(to).and_return(credentials)
        allow(credentials).to receive(:s3_options).and_return(s3_credential_options)
        allow(Aws::S3::Client).to receive(:new).with({region: "service_endpoint"}.merge(s3_credential_options)).and_return(s3_client)
        allow(Aws::S3::Resource).to receive(:new).with({client: s3_client}).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).with("bucket").and_return(bucket)
        allow(gateway).to receive(:receive_message).with(message).and_return(source_stream)
        allow(bucket).to receive(:put_object).with({
          key: "file_name",
          content_length: 300,
          body: source_io_stream
        })
        allow(source_stream).to receive(:cleanup)
        subject.assign_providers(gateway, credential_provider)
      end

      it "creates the client with the credentials and connection info" do
        expected_information = {
           region: "service_endpoint"
        }.merge(s3_credential_options)
        expect(Aws::S3::Client).to receive(:new).with(expected_information).and_return(s3_client)
        subject.send_message(message)
      end

      it "uploads the body to the key" do
        expected_information = {
          key: "file_name",
          content_length: 300,
          body: source_io_stream
        }
        expect(bucket).to receive(:put_object).with(expected_information)
        subject.send_message(message)
      end
    end
  end

  describe Adapters::S3Adapter, "#receive_message" do
    let(:message) { ::TransportGateway::Message.new(from: from, source_credentials: source_credentials) }

    describe "given:
      - no 'from'
    " do

      let(:from) { nil }
      let(:source_credentials) { nil }

      it "raises an error" do
        expect{ subject.receive_message(message) }.to raise_error(ArgumentError, /source data not provided/)
      end
    end

    describe "given:
      - a valid 'from'
      - no credential provider
      - no source credentials 
    " do

      let(:from) { URI.parse("s3://bucket@place/object_key") }
      let(:source_credentials) { nil }

      it "raises an error" do
        expect { subject.receive_message(message) }.to raise_error(ArgumentError, /credentials not found for uri/)
      end
    end

    describe "given:
      - a valid 'from'
      - a message with source credentials
    " do

      let(:from) { URI.parse("s3://bucket@service_endpoint/object_key") }
      let(:source_credentials) { double }

      let(:s3_client) do
        instance_double(Aws::S3::Client)
      end

      let(:s3_resource) do
        instance_double(Aws::S3::Resource)
      end

      let(:bucket) do
        instance_double(Aws::S3::Bucket)
      end

      let(:object) do
        instance_double(Aws::S3::Object)
      end

      let(:tempfile) do
        instance_double(Tempfile, :binmode => true)
      end

      let(:s3_credential_options) do
        {
          access_key_id: "ACCESS KEY",
          secret_access_key: "SECRET ACCESS KEY"
        }
      end

      let(:temp_file_source) { instance_double(TransportGateway::Sources::TempfileSource) }

      before :each do
        allow(source_credentials).to receive(:s3_options).and_return(s3_credential_options)
        allow(Aws::S3::Client).to receive(:new).with({region: "service_endpoint"}.merge(s3_credential_options)).and_return(s3_client)
        allow(Aws::S3::Resource).to receive(:new).with({client: s3_client}).and_return(s3_resource)
        allow(s3_resource).to receive(:bucket).with("bucket").and_return(bucket)
        allow(bucket).to receive(:object).with("object_key").and_return(object)
        allow(Tempfile).to receive(:new).with("object_key").and_return(tempfile)
        allow(object).to receive(:get).with({:response_target => tempfile})
        allow(TransportGateway::Sources::TempfileSource).to receive(:new).with(tempfile).and_return(temp_file_source)
      end

      it "download the file" do
        expect(object).to receive(:get).with({:response_target => tempfile})
        subject.receive_message(message)
      end

      it "provides the download as a source" do
        expect(subject.receive_message(message)).to eq temp_file_source
      end
    end
  end
end
