require 'rails_helper'

require File.expand_path(File.join(File.dirname(__FILE__), "shared_adapter"))

module TransportGateway
  describe Adapters::SftpAdapter, "#send_message" do
    let(:message) { Message.new(from: from, to: to, body: body) }
    let(:user_name) { "A user name" }
    let(:user_password) { "someC#*($&:;:DERAZY pwd" }
    let(:user_credentials) { double(:user => user_name, :sftp_options => { :password => user_password }) }
    let(:userinfo)  { "#{ERB::Util.url_encode(user_name)}:#{ERB::Util.url_encode(user_password)}" }
    let(:target_host)   { "ftp.example.com" }
    let(:target_folder) { "/path/to/target/folder" }
    let(:target_file_name) { "some_file.pdf" }
    let(:target_path)   { File.join(target_folder, target_file_name) }
    let(:sftp_session) { instance_double(Net::SFTP::Session) }

    subject { Adapters::SftpAdapter.new }

    before :each do
      subject.assign_providers(nil, nil)
    end

    it_behaves_like "a transport gateway adapter, sending a message"

    describe "given:
    - no credentials in the URI
    - no credential provider
    " do
      let(:body)          { "MY MESSAGE BODY" }
      let(:from)      { nil }
      let(:to)        { URI::FTP.build({ host: target_host, path: target_path, scheme: "sftp" }) }

      before :each do
        subject.assign_providers(nil, nil)
      end

      it "raises an error" do
        expect{ subject.send_message(message) }.to raise_error(ArgumentError, /target server username:password not provided/ ) 
      end
    end

    describe "given:
    - no credentials in the URI
    - a credential provider with no matching credentials
    - a message body
    " do
      let(:gateway) { double }
      let(:body)          { "MY MESSAGE BODY" }
      let(:from)      { nil }
      let(:to)        { URI::FTP.build({ host: target_host, path: target_path, scheme: "sftp" }) }

      let(:credential_provider) { double }

      before(:each) do
        subject.assign_providers(gateway, credential_provider)
        allow(credential_provider).to receive(:credentials_for).with(to).and_return(nil)
      end

      it "raises an error" do
        expect { subject.send_message(message) }.to raise_error(ArgumentError, /target server username:password not provided/ ) 
      end
    end

    describe "given:
    - credentials in the URI
    - no source file
    - no message body
    " do
      let(:body)          { nil }
      let(:from)      { nil }
      let(:to)        { URI::FTP.build({ host: target_host, path: target_path, scheme: "sftp" }) }

      before :each do
        subject.assign_providers(nil, nil)
      end

      it "raises an error" do
        expect{ subject.send_message(message) }.to raise_error(ArgumentError, /source data not provided/) 
      end
    end

    describe "given:
    - valid user credentials in the URI
    - a valid destination
    - the payload as the message body
    - the target directory DOES NOT exist
    " do
      let(:body)          { "MY MESSAGE BODY" }
      let(:from)      { nil }
      let(:to)        { URI::FTP.build({ host: target_host, path: target_path, userinfo: userinfo, scheme: "sftp" }) }

      let(:body_io) { double }

      before :each do
        allow(Net::SFTP).to receive(:start).with(target_host, user_name, {password: user_password, :non_interactive => true}).and_yield(sftp_session)
        allow(sftp_session).to receive(:stat!).with(target_folder).and_raise(RuntimeError.new)
        allow(StringIO).to receive(:new).with(body).and_return(body_io)
        allow(sftp_session).to receive(:upload!).with(body_io, target_path).and_return(nil)
      end

      it "creates the target directory" do
        expect(sftp_session).to receive(:mkdir!).with(target_folder).and_return(nil)
        subject.send_message(message)
      end

    end

    describe "given:
    - valid user credentials in the URI
    - a valid destination
    - the payload as the message body
    - the target directory already exists
    " do
      let(:body)          { "MY MESSAGE BODY" }
      let(:from)      { nil }
      let(:to)        { URI::FTP.build({ host: target_host, path: target_path, userinfo: userinfo, scheme: "sftp" }) }

      let(:body_io) { double }

      before :each do
        allow(Net::SFTP).to receive(:start).with(target_host, user_name, { password: user_password, :non_interactive => true}).and_yield(sftp_session)
        allow(sftp_session).to receive(:stat!).with(target_folder).and_return(true)
        allow(StringIO).to receive(:new).with(body).and_return(body_io)
      end

      it "uploads the message succesfully" do
        expect(sftp_session).to receive(:upload!).with(body_io, target_path).and_return(nil)
        subject.send_message(message)
      end

    end

    describe "given:
    - no user credentials in the URI
    - a credential provider which has credentials for the target
    - a valid destination
    - the payload as the message body
    - the target directory already exists
    " do
      let(:gateway) { double }
      let(:body)          { "MY MESSAGE BODY" }
      let(:from)      { nil }
      let(:to)        { URI::FTP.build({ host: target_host, path: target_path, scheme: "sftp" }) }

      let(:body_io) { double }
      let(:credential_provider) { double }

      before :each do
        subject.assign_providers(gateway, credential_provider)
        allow(credential_provider).to receive(:credentials_for).with(to).and_return(user_credentials)
        allow(Net::SFTP).to receive(:start).with(target_host, user_name, { password: user_password, non_interactive: true }).and_yield(sftp_session)
        allow(sftp_session).to receive(:stat!).with(target_folder).and_return(true)
        allow(StringIO).to receive(:new).with(body).and_return(body_io)
      end

      it "uploads the message succesfully" do
        expect(sftp_session).to receive(:upload!).with(body_io, target_path).and_return(nil)
        subject.send_message(message)
      end

    end

    describe "given:
    - no user credentials in the URI
    - a credential provider which has credentials for the target
    - a valid destination
    - no message body
    - the target directory already exists
    - a 'to' source uri
    " do
      let(:gateway) { instance_double(::TransportGateway::Gateway) }
      let(:body)          { nil }
      let(:from)      { double }
      let(:to)        { URI::FTP.build({ host: target_host, path: target_path, scheme: "sftp" }) }

      let(:body_io) { double }
      let(:credential_provider) { double }
      let(:message_source) { double(:stream => body_io, :cleanup => nil) }

      before :each do
        subject.assign_providers(gateway, credential_provider)
        allow(gateway).to receive(:receive_message).with(message).and_return(message_source)
        allow(credential_provider).to receive(:credentials_for).with(to).and_return(user_credentials)
        allow(Net::SFTP).to receive(:start).with(target_host, user_name, {password: user_password, non_interactive: true}).and_yield(sftp_session)
        allow(sftp_session).to receive(:stat!).with(target_folder).and_return(true)
      end

      it "uploads the message succesfully" do
        expect(sftp_session).to receive(:upload!).with(body_io, target_path).and_return(nil)
        subject.send_message(message)
      end

    end

  end

  describe Adapters::SftpAdapter, "#receive_message" do
    let(:credential_provider) { double }
    let(:gateway) { double }
    let(:message) { Message.new(from: from, to: to, body: body) }
    let(:user_name) { "A user name" }
    let(:user_password) { "someC#*($&DERAZY pwd" }
    let(:user_credentials) { double(:user => user_name, :sftp_options => {:password => user_password}) }
    let(:userinfo)  { "#{URI.escape(user_name)}:#{URI.escape(user_password)}" }
    let(:source_host)   { "ftp.example.com" }
    let(:source_folder) { "/path/to/target/folder" }
    let(:source_file_name) { "some_file.pdf" }
    let(:source_path)   { File.join(source_folder, source_file_name) }
    let(:sftp_session) { instance_double(Net::SFTP::Session) }
    let(:body) { nil }
    let(:to) { nil }

    subject { Adapters::SftpAdapter.new }

    describe "given:
    - no source 
    " do
      let(:from)      { nil }

      before :each do
        subject.assign_providers(gateway, credential_provider)
      end

      it "raises an error" do
        expect{ subject.receive_message(message) }.to raise_error(ArgumentError, /source file not provided/) 
      end
    end

    describe "given:
    - no credentials in the URI
    - a credential provider with no matching credentials
    " do
      let(:gateway) { double }
      let(:from)        { URI::FTP.build({ host: source_host, path: source_path, scheme: "sftp" }) }

      let(:credential_provider) { double }

      before(:each) do
        subject.assign_providers(gateway, credential_provider)
        allow(credential_provider).to receive(:credentials_for).with(from).and_return(nil)
      end

      it "raises an error" do
        expect { subject.receive_message(message) }.to raise_error(ArgumentError, /source server username:password not provided/ ) 
      end
    end

    describe "given:
    - valid user credentials in the URI
    - a valid source
    " do
      let(:from)        { URI::FTP.build({ host: source_host, path: source_path, scheme: "sftp", userinfo: userinfo }) }
      let(:tempfile) { double(:binmode => true) }
      let(:download_file) { double }

      before :each do
        allow(Tempfile).to receive(:new).with('tgw_sftp_adapter_dl').and_return(tempfile)
        allow(Sources::TempfileSource).to receive(:new).with(tempfile).and_return(download_file)
        allow(Net::SFTP).to receive(:start).with(source_host, user_name, {password: user_password, non_interactive: true}).and_yield(sftp_session)
      end

      it "downloads the file" do
        expect(sftp_session).to receive(:download!).with(source_path, tempfile).and_return(nil)
        expect(subject.receive_message(message)).to eq download_file
      end
    end
  end
end
