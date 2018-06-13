require 'rails_helper'
require 'net/http'

module TransportGateway
  RSpec.describe Adapters::HttpAdapter, type: :model do
    let(:adapter)     { Adapters::HttpAdapter.new }

    before(:each) do
      stub_request(:put, /www.example.com/).to_return(status: 200, body: "http stubbed response", headers: {})
    end

    context "Post content to HTTP server resource" do
      let(:from)        { "foo@bar.com" }
      let(:host)        { "www.example.com"}
      let(:path)        { "/path/to/resource" }
      let(:url)         { host + path }
      let(:text_string) { "madam in eden i'm adam" }

      context "and the endpoint is available" do
        let(:to)        { URI::HTTP.build({ host: host, path: path }) } 
        let(:message)   { Message.new(from: from, to: to, body: text_string) }

        it "the URL should return a HTTP success status" do
          response = adapter.send_message(message)
          expect(response).to be_kind_of Net::HTTPSuccess
        end

        context "and Put request with text body is sent without credentials" do
          let(:message)     { Message.new(from: from, to: to, body: text_string) }

          it "should post text string payload to the server" do
            adapter.send_message(message)

            expect(WebMock).to have_requested(:put, url).
              with(body: text_string, headers: { content_type: 'text/plain'}).once
          end
        end

        context "and Put request with text body is sent with Basic Authentication User and Password" do
          let(:user)          { "foo" }
          let(:password)      { "secret_password" }
          let(:userinfo)      { user + ':' + password }
          let(:to)            { URI::HTTP.build({ host: host, path: path, userinfo: userinfo }) } 
          let(:message)       { Message.new(from: from, to: to, body: text_string) }

          it "should post text string payload to the server with credentials in header" do
            adapter.send_message(message)

            expect(WebMock).to have_requested(:put, url).
              with(basic_auth: [user, password], body: text_string, headers: { content_type: 'text/plain'}).once
          end
        end

        context "and Put request with file content is posted to server" do
          let(:file_folder) { File.join(File.expand_path("../../../..", __FILE__), "test_files") }
          let(:file_name)   { File.join(file_folder, "text_file.txt") }
          let(:file_handle) { File.new(file_name) }
          let(:file_data)   { File.read(file_name) }
          let(:to)          { URI::HTTP.build({ host: host, path: path }) } 
          let(:message)     { Message.new(from: from, to: to, body: file_handle) }

          it "should post file content payload to the server" do
            adapter.send_message(message)

            expect(WebMock).to have_requested(:put, url).
              with(body: file_data, headers: { content_type: 'text/plain'}).once
          end

        end

      end

      context "using SSL" do
        # let(:cert_file)   { File.join(file_folder, "key.pem") }
        # http.use_ssl = true
        # http.cert = OpenSSL::X509::Certificate.new(pem)
        # http.key = OpenSSL::PKey::RSA.new(pem)
        # http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end


  end
end
