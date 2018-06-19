require "rails_helper"

module TransportProfiles
  describe Steps::ListEntries do
    let(:entry1_uri) { URI.parse("sftp://some_server/some_folder/some_file1.txt") }
    let(:entry2_uri) { URI.parse("sftp://some_server/some_folder/some_file2.txt") }
    let(:entry1) { instance_double(::TransportGateway::ResourceEntry, :name => "file_1.csv", :uri => entry1_uri, :mtime => 27) }
    let(:entry2) { instance_double(::TransportGateway::ResourceEntry, :name => "file_2.xml", :uri => entry2_uri, :mtime => 1) }

    let(:process) { instance_double(::TransportProfiles::Processes::Process) }
    let(:process_context) { ::TransportProfiles::ProcessContext.new(process) }
    let(:gateway) { instance_double(::TransportGateway::Gateway) }
    let(:endpoint) { instance_double(::TransportProfiles::WellKnownEndpoint, uri: endpoint_uri_string) }
    let(:endpoint_uri_string) { "sftp://some_endpoint_server/some_folder" }
    let(:endpoint_uri) { URI.parse("sftp://some_endpoint_server/some_folder") }
    let(:resource_query) { instance_double(::TransportGateway::ResourceQuery) }


    before :each do
#      allow(URI).to receive(:parse).with(endpoint_uri_string).and_return(endpoint_uri)
      allow(::TransportGateway::ResourceQuery).to receive(:new).with({:from => endpoint_uri, :source_credentials => endpoint}).and_return(resource_query)
      allow(::TransportProfiles::WellKnownEndpoint).to receive(:find_by_endpoint_key).with(:endpoint_1).and_return([endpoint])
      allow(gateway).to receive(:list_entries).with(resource_query).and_return([entry1, entry2])
    end

    describe  "given no filter on the results" do
      subject { ::TransportProfiles::Steps::ListEntries.new(:endpoint_1, :file_list, gateway) }

      it "places the list of all returned results in the context" do
        subject.execute(process_context)
        expect(process_context.get(:file_list)).to include(entry1_uri, entry2_uri)
      end 
    end

    describe  "given a filter for xml files" do
      subject do 
        ::TransportProfiles::Steps::ListEntries.new(:endpoint_1, :file_list, gateway) do |entries|
          entries.select do |entry|
            entry.name =~ /\.xml\Z/i
          end
        end
      end

      it "places the only the xml results in the context" do
        subject.execute(process_context)
        expect(process_context.get(:file_list)).to include(entry2_uri)
      end 
    end

    describe  "given a filter for the most recent file" do
      subject do 
        ::TransportProfiles::Steps::ListEntries.new(:endpoint_1, :file_list, gateway) do |entries|
          entries.any? ? [entries.sort_by(&:mtime).last] : []
        end
      end

      it "places the only the most recent result in the context" do
        subject.execute(process_context)
        expect(process_context.get(:file_list)).to include(entry1_uri)
      end 
    end

    describe  "given a filter to not re-upload the most recent file" do
      let(:entry1_dupe_uri) { URI.parse("sftp://some_other_server/some_other_folder/some_file1.txt") }

      before :each do
        process_context.put(:already_uploaded_files, [entry1_dupe_uri])
      end

      subject do 
        ::TransportProfiles::Steps::ListEntries.new(:endpoint_1, :file_list, gateway) do |entries, process_context|
          most_recent_entries = entries.any? ? [entries.sort_by(&:mtime).last] : []
          already_sent_entries = process_context.get(:already_uploaded_files)
          already_sent_file_names = already_sent_entries.map { |entry| File.basename(entry.path) }
          most_recent_entries.reject { |entry| already_sent_file_names.include?(File.basename(entry.uri.path)) }
        end
      end

      it "does not choose any files" do
        subject.execute(process_context)
        expect(process_context.get(:file_list)).not_to include(entry1_uri)
      end 
    end
  end
end
