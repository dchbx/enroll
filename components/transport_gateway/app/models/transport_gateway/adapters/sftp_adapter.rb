require 'net/ssh'
require 'net/sftp'
require 'tempfile'

module TransportGateway
  class Adapters::SftpAdapter
    include ::TransportGateway::Adapters::Base

    attr_accessor :user
    attr_accessor :credential_options

    def list_entries(resource_query)
      if resource_query.from.blank?
        log(:error, "transport_gateway.sftp_adapter") { "query endpoint not provided" }
        raise ArgumentError.new "query endpoint not provided"
      end

      target_uri = resource_query.from

      resolve_from_credentials(resource_query)
      if @user.blank? || @credential_options.blank?
        log(:error, "transport_gateway.sftp_adapter") { "source server credentials not found" }
        raise ArgumentError.new("source server username:password not provided")
      end

      begin
        result_list = []
        Net::SFTP.start(target_uri.host, @user, default_options.merge(credential_options)) do |sftp|
          sftp.dir.foreach(target_uri.path) do |entry|
            if entry.file?
              full_uri = URI.join(target_uri, URI.encode(entry.name))
              result_list << TransportGateway::ResourceEntry.new(entry.name, full_uri, entry.attributes.size, entry.attributes.mtime)
            end
          end
        end
        result_list
      rescue Exception => e
        log(:error, "transport_gateway.sftp_adapter") { e }
        raise e
      end
    end

    def receive_message(message)
      if message.from.blank?
        log(:error, "transport_gateway.sftp_adapter") { "source file not provided" }
        raise ArgumentError.new "source file not provided"
      end

      target_uri = message.from

      resolve_from_credentials(message)
      if @user.blank? || @credential_options.blank?
        log(:error, "transport_gateway.sftp_adapter") { "source server credentials not found" }
        raise ArgumentError.new("source server username:password not provided")
      end
      
      source_stream = Tempfile.new('tgw_sftp_adapter_dl')
      source_stream.binmode

      begin
        Net::SFTP.start(target_uri.host, @user, default_options.merge(credential_options)) do |sftp|
          sftp.download!(URI.decode(target_uri.path), source_stream)
        end
        Sources::TempfileSource.new(source_stream)
      rescue Exception => e
        log(:error, "transport_gateway.sftp_adapter") { e }
        source_stream.close
        source_stream.unlink
        raise e
      end
    end

    def send_message(message)
      if (message.from.blank? && message.body.blank?)
        log(:error, "transport_gateway.sftp_adapter") { "source data not provided" }
        raise ArgumentError.new "source data not provided"
      end
      unless message.to.present?
        log(:error, "transport_gateway.sftp_adapter") { "destination not provided" }
        raise ArgumentError.new "destination not provided"
      end

      target_uri = message.to

      resolve_to_credentials(message)
      if @user.blank? || @credential_options.blank?
        log(:error, "transport_gateway.sftp_adapter") { "target server credentials not found" }
        raise ArgumentError.new("target server username:password not provided")
      end

      source = provide_source_for(message)

      begin
        Net::SFTP.start(target_uri.host, @user, default_options.merge(@credential_options)) do |sftp|
          find_or_create_target_folder_for(sftp, URI.decode(target_uri.path))

          sftp.upload!(source.stream, URI.decode(target_uri.path))
        end
      rescue Exception => e
        log(:error, "transport_gateway.sftp_adapter") { e }
        raise e
      ensure
        source.cleanup
      end
    end

    def resolve_from_credentials(message)
      cr = CredentialResolvers::SftpCredentialResolver.new(message, credential_provider)
      creds = cr.source_credentials
      unless creds.blank?
        @user = creds.user
        @credential_options = creds.sftp_options
      end
    end

    def resolve_to_credentials(message)
      cr = CredentialResolvers::SftpCredentialResolver.new(message, credential_provider)
      creds = cr.destination_credentials
      unless creds.blank?
        @user = creds.user
        @credential_options = creds.sftp_options
      end
    end

    def provide_source_for(message)
      unless message.body.blank?
        return Sources::StringIOSource.new(message.body)
      end
      gateway.receive_message(message)
    end

    def send_messages(messages)
      handle1 = sftp.open!("/path/to/file1")
      handle2 = sftp.open!("/path/to/file2")

      r1 = sftp.read(handle1, 0, 1024)
      r2 = sftp.read(handle2, 0, 1024)

      sftp.loop { [r1, r2].any? { |r| r.pending? } }

      puts "chunk #1: #{r1.response[:data]}"
      puts "chunk #2: #{r2.response[:data]}"
    end

    private
    def find_or_create_target_folder_for(sftp, path)
      folder = File.dirname(path)
      begin
        sftp.stat!(folder)
      rescue
        sftp.mkdir!(folder)
      end
    end


    # open session and block until connection is initialized
    def open_session(ssh)
      sftp = Net::SFTP::Session.new(ssh)
      sftp.loop { sftp.opening? }
      sftp
    end

    def open(uploader, *args)
      Rails.logger("Starting upload...")
    end

    def close(uploader, *args)
      Rails.logger("Upload complete")
    end

    def finish(uploader, *args)
      Rails.logger("All done")
    end

    def default_options
      { :non_interactive => true }
    end

  end
end
