require "rails_helper"

module TransportProfiles
  describe Steps::RouteTo, "given:
    - an endpoint key
    - a file name
    - a gateway
  " do

    let(:endpoint_key) { "MY FRIENDLY ENDPOINT" }
    let(:file_name) { "FileReports%20_FOR_%20Example.pdf" }
    let(:gateway) { double }

    let(:route_to) do
      Steps::RouteTo.new(endpoint_key, file_name, gateway)
    end

    describe "#complete_uri_for", "given:
      - a found sftp endpoint
      - a file name made into a uri
    " do
      let(:file_uri) { URI.parse("file:///some/bogus/path/to/whatever/FileReports%20_FOR_%20Example.pdf") }
      let(:endpoint) do 
        instance_double(
          WellKnownEndpoint,
          {
            uri: "sftp://some_user@whatever.com/a/dropoff/path"
          }
        )
      end

      let(:expected_complete_uri) { URI.parse("sftp://some_user@whatever.com/a/dropoff/FileReports%20_FOR_%20Example.pdf") }
  
      it "adds the file name to the sftp" do
        expect(route_to.complete_uri_for(endpoint, file_uri)).to eq expected_complete_uri
      end
    end

    describe "#complete_uri_for", "given:
      - a found s3_endpoint
      - a file name made into a uri
    " do
      let(:file_uri) { URI.parse("file:///some/bogus/path/to/whatever/FileReports%20_FOR_%20Example.pdf") }
      let(:endpoint) do 
        instance_double(
          WellKnownEndpoint,
          {
            uri: "s3://bucket@region/"
          }
        )
      end

      let(:uuid) { "63d162e4-908b-702961-e4ec-41a1060f3f" }
      let(:random_stuff) { uuid.gsub("-", "").reverse }

      let(:expected_complete_uri) { URI.parse("s3://bucket@region/#{random_stuff}_FileReports%20_FOR_%20Example.pdf") }

      before(:each) do
        allow(SecureRandom).to receive(:uuid).and_return(uuid)
      end
  
      it "adds the file name to the sftp" do
        expect(route_to.complete_uri_for(endpoint, file_uri)).to eq expected_complete_uri
      end
    end

  end
end
