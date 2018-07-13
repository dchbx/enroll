require "rails_helper"

module TransportProfiles
  module Processes
    class TestingStubTransportProcess
      def initialize(file_name, gateway, destination_file_name: nil, source_credentials: nil)
      end

      def execute
      end
    end
  end

  describe ArtifactTransportRequest, "performing validations" do
    before :each do
      subject.valid?
    end

    it "requires file_name" do
      expect(subject.errors.has_key?(:file_name)).to be_truthy
    end

    it "requires transport_process" do
      expect(subject.errors.has_key?(:transport_process)).to be_truthy
    end

    it "requires artifact_key" do
      expect(subject.errors.has_key?(:artifact_key)).to be_truthy
    end
  end

  describe ArtifactTransportRequest, "given an invalid transport process" do
    subject do
      ArtifactTransportRequest.new(
        "file_name" => "the_file_name.pdf",
        "artifact_key" => "the_artifact_key",
        "transport_process" => transport_process
      )
    end

    let(:transport_process) { "BOGUS PROCESS NAME" }

    before :each do
      subject.valid?
    end

    it "provides the error" do
      expect(subject.errors[:transport_process].first).to eq "#{transport_process} is an invalid transport process"
    end
  end

  describe ArtifactTransportRequest, "given:
    - a file name
    - an artifact key
    - a valid transport process
  " do
    subject do
      ArtifactTransportRequest.new(
        "file_name" => "the_file_name.pdf",
        "artifact_key" => "the_artifact_key",
        "transport_process" => transport_process
      )
    end

    let(:transport_process) { "TestingStubTransportProcess" }

    let(:testing_transport_process) { instance_double(Processes::TestingStubTransportProcess) }
    let(:gateway) { instance_double(TransportGateway::Gateway) }
    let(:source_endpoint) { instance_double(WellKnownEndpoint, :uri => s3_transport_uri) }

    let(:s3_transport_uri) { "s3://bucket@us-east" }
    let(:expected_source_uri) { URI.join(s3_transport_uri, "the_artifact_key") }

    before :each do
      allow(TransportGateway::Gateway).to receive(:new).with(nil, Rails.logger).and_return(gateway)
      allow(TransportProfiles::WellKnownEndpoint).to receive(:find_by_endpoint_key).with("aca_internal_artifact_transport").and_return([source_endpoint])
    end

    it "is valid" do 
      expect(subject.valid?).to be_truthy
    end

    it "executes the transport process for the artifact" do
      expect(TransportProfiles::Processes::TestingStubTransportProcess).to receive(:new).with(
        expected_source_uri,
        gateway,
        destination_file_name: "the_file_name.pdf",
        source_credentials: source_endpoint
      ).and_return(testing_transport_process)
      expect(testing_transport_process).to receive(:execute)
      subject.execute
    end
  end
end
