require 'rails_helper'
require 'net/http'

require File.expand_path(File.join(File.dirname(__FILE__), "shared_adapter"))

module TransportGateway
  describe Adapters::FileAdapter, "#send_message" do
    let(:message) { ::TransportGateway::Message.new(to: to, from: from, body: body) }

    before :each do
      subject.assign_providers(nil, nil)
    end

    subject { Adapters::FileAdapter.new }

    it_behaves_like "a transport gateway adapter, sending a message"

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
        expect{ subject.send_message(message) }.to raise_error(ArgumentError, /source file not provided/)
      end
    end

    describe "given:
      - a message body
      - a destination with a directory that exists
    " do

      let(:out_file_path) { File.join(Rails.root, "file_adapter_message_send_dir_exists") }
      let(:body) { "THE BODY DATA" }
      let(:from) { nil }
      let(:to) do
        to_uri = URI.parse("file:///")
        to_uri.path = out_file_path
        to_uri
      end

      before :each do
        FileUtils.rm_f(out_file_path)
      end

      it "writes the body to the file" do
        subject.send_message(message)
        expect(File.read(to.path)).to eq body
      end

      after :each do
        FileUtils.rm_f(out_file_path)
      end
    end

    describe "given:
      - a message body
      - a destination with a directory that does not exist
    " do

      let(:out_file_path) { File.join(Rails.root, "file_adapter_message_send_dir_not_exist/test_file") }
      let(:body) { "THE BODY DATA" }
      let(:from) { nil }
      let(:to) do
        to_uri = URI.parse("file:///")
        to_uri.path = out_file_path
        to_uri
      end

      before(:each) do
        FileUtils.remove_dir(File.dirname(out_file_path), true)
      end

      it "creates the directory" do
        subject.send_message(message)
        expect(File.exist?(File.dirname(out_file_path))).to be_truthy
      end

      it "writes the body to the file" do
        subject.send_message(message)
        expect(File.read(to.path)).to eq body
      end

      after :each do
        FileUtils.remove_dir(File.dirname(out_file_path), true)
      end
    end

    describe "given:
      - an empty body
      - a message source 
      - a destination with a directory that exists
    " do

      let(:out_file_path) { File.join(Rails.root, "file_adapter_message_send_dir_exists") }
      let(:body) { nil }
      let(:body_data) { "THE BODY STRING" }
      let(:from) { double }
      let(:to) do
        to_uri = URI.parse("file:///")
        to_uri.path = out_file_path
        to_uri
      end
      let(:gateway) { instance_double(TransportGateway::Gateway) }
      let(:message_source) { TransportGateway::Sources::StringIOSource.new(body_data) }

      before :each do
        FileUtils.rm_f(out_file_path)
        subject.assign_providers(gateway, nil)
        allow(gateway).to receive(:receive_message).with(message).and_return(message_source)
      end

      it "writes the body to the file" do
        subject.send_message(message)
        expect(File.read(to.path)).to eq body_data
      end

      after :each do
        FileUtils.rm_f(out_file_path)
      end
    end
  end

  describe Adapters::FileAdapter, "#receive_message" do
    let(:message) { ::TransportGateway::Message.new(to: to, from: from, body: body) }
    let(:gateway) { double }

    subject { Adapters::FileAdapter.new }

    before :each do
      subject.assign_providers(gateway, nil)
    end

    describe "given:
      - no 'from'
      - a log observer
    " do
      let(:log_observer) { double }
      let(:body) { nil }
      let(:to) { URI.parse("file:///somewhere") }
      let(:from) { nil }

      before :each do
        allow(log_observer).to receive(:update) do |level,tag,blk|
        end 
        subject.assign_providers(nil, nil)
        subject.add_observer(log_observer)
      end

      it "raises an error" do
        expect{ subject.receive_message(message) }.to raise_error(ArgumentError, /source file not provided/)
      end

      it "logs the error" do
        expect(log_observer).to receive(:update) do |level,tag,blk|
          expect(level).to eq :error
          expect(tag).to eq "transport_gateway.file_adapter"
          expect(blk.call).to eq "source file not provided"
        end 
        expect { subject.receive_message(message) }.to raise_error(ArgumentError, /source file not provided/)
      end
    end

    describe "given:
      - a valid 'from' with data
    " do

      let(:in_file_path) { File.join(Rails.root, "file_adapter_message_receive") }
      let(:body) { nil }
      let(:file_data) { "THE BODY DATA" }
      let(:to) { nil }
      let(:from) do
        to_uri = URI.parse("file:///")
        to_uri.path = in_file_path 
        to_uri
      end

      before :each do
        FileUtils.rm_f(in_file_path)
        File.open(in_file_path, 'wb') do |f|
          f.write(file_data)
        end
      end

      it "provides a source containing the data" do
        source = subject.receive_message(message)
        expect(source.stream.read).to eq file_data
        source.stream.close
      end

      after :each do
        FileUtils.rm_f(in_file_path)
      end
    end
  end
end
