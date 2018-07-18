require "rails_helper"

module TransportProfiles
  describe Subscribers::TransportArtifactSubscriber do
    subject do
      Subscribers::TransportArtifactSubscriber.new
    end

    let(:payload) do
      double(:headers =>
      {
        :file_name => file_name,
        :artifact_key => artifact_key,
        :transport_process => transport_process
      })
    end

    let(:request_properties) do
      {
        :file_name => file_name,
        :artifact_key => artifact_key,
        :transport_process => transport_process
      }
    end

    let(:file_name) { "some_pdf.pdf" }
    let(:artifact_key) { "the_artifact_key" }
    let(:transport_process) { "some transport process" }

    let(:errors_hash) do
      { "file_name" => ["can't be blank"] }
    end

    let(:request) { instance_double(ArtifactTransportRequest, :errors => double(:to_hash => errors_hash)) }

    describe "given an invalid request" do
      before :each do
        allow(ArtifactTransportRequest).to receive(:new).with(request_properties).and_return(request)
        allow(request).to receive(:valid?).and_return(false)
      end

      it "logs an error" do
        expect(subject).to receive(:notify).with(
          "acapi.error.events.transport_artifact.invalid_transport_request",
          {
            :return_status => "422",
            :body => JSON.dump({
              "file_name" => ["can't be blank"]
            })
          }
        )
        subject.work_with_params("", nil, payload)
      end
    end

    describe "given a valid request, with no execution errors" do
      before :each do
        allow(ArtifactTransportRequest).to receive(:new).with(request_properties).and_return(request)
        allow(request).to receive(:valid?).and_return(true)
      end

      it "executes the request" do
        expect(request).to receive(:execute)
        subject.work_with_params("", nil, payload)
      end
    end

  end
end
