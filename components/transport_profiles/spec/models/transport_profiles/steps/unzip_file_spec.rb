require 'rails_helper'

describe ::TransportProfiles::Steps::UnzipFile do
  describe "with a local zip file" do

    let(:process) { instance_double(::TransportProfiles::Processes::Process) }
    let(:gateway) { ::TransportGateway::Gateway.new(nil, Rails.logger) }
    let(:local_zip_file_path) { URI.join("file://", URI.escape(File.join(File.dirname(__FILE__), "../../../test_data/a_simple_zip_file.zip"))) }
    let(:process_context) { ::TransportProfiles::ProcessContext.new(process) }

    subject { ::TransportProfiles::Steps::UnzipFile.new(local_zip_file_path, :key_where_my_file_list_goes, :list_of_temp_dirs, gateway) }

    before :each do
      subject.execute(process_context)
    end

    it "should create the temporary directory to unzip the files" do
      expect(process_context.get(:list_of_temp_dirs)).not_to eq nil
    end

    it "should create the output files" do
      output_file_names = process_context.get(:key_where_my_file_list_goes)
      output_dir_name = process_context.get(:list_of_temp_dirs).first
      unzipped_file_names = output_file_names.map do |f_name_uri|
        URI.decode(f_name_uri.path.split(URI.encode(output_dir_name) + "/").last)
      end
    end

    it "can be cleaned up after" do
      output_dir_name = process_context.get(:list_of_temp_dirs)
      output_dir_name.each do |d_name|
        expect(File.exists?(d_name)).to be_truthy
      end
      process_context.execute_cleanup
      output_dir_name.each do |d_name|
        expect(File.exists?(d_name)).to be_falsey
      end
    end
  end
end
