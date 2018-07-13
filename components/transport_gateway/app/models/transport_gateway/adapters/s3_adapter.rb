require "pathname"

module TransportGateway
  class Adapters::S3Adapter
    include ::TransportGateway::Adapters::Base

    def receive_message(message)
      if message.from.blank?
        log(:error, "transport_gateway.s3_adapter ") { "source data not provided" }
        raise ArgumentError.new "source data not provided"
      end

      credentials = check_source_credential_provider(message)
      check_s3_uri(message.from)

      bucket = message.from.bucket
      region = message.from.region
      key = message.from.key

      tempfile = Tempfile.new(key)
      tempfile.binmode
      begin
        client = Aws::S3::Client.new({
          :region => region
        }.merge(credentials))
        resource = Aws::S3::Resource.new(client: client)
        bucket = resource.bucket(bucket)
        object = bucket.object(key)

        object.get({response_target: tempfile})
        TransportGateway::Sources::TempfileSource.new(tempfile)
      rescue Exception => e
        log(:error, "transport_gateway.s3_adapter") { e }
        tempfile.close
        tempfile.unlink
        raise e
      end
    end

    def send_message(message)
      if (message.from.blank? && message.body.blank?)
        log(:error, "transport_gateway.s3_adapter ") { "source data not provided" }
        raise ArgumentError.new "source data not provided"
      end

      unless message.to.present?
        log(:error, "transport_gateway.s3_adapter") { "destination not provided" }
        raise ArgumentError.new "destination not provided"
      end

      check_s3_uri(message.to)
      bucket = message.to.bucket
      region = message.to.region
      key = message.to.key

      credentials = check_credential_provider(message)

      client = Aws::S3::Client.new({
        :region => region
      }.merge(credentials))
      resource = Aws::S3::Resource.new(client: client)
      bucket = resource.bucket(bucket)
      if message.body.blank?
        source = gateway.receive_message(message)
        begin
          bucket.put_object({
            key: key,
            body: source.stream,
            content_length: source.size
          })
        rescue Exception => e
          log(:error, "transport_gateway.s3_adapter") { e }
          raise e
        ensure
          source.cleanup
        end
      else
        bucket.put_object({
          key: key,
          body: message.body,
          content_length: message.body.bytesize
        })
      end
    end

    def check_source_credential_provider(message)
      cr = CredentialResolvers::S3CredentialResolver.new(message, credential_provider)
      credentials = cr.source_credentials
      if credentials.blank?
        raise ArgumentError.new("credentials not found for uri")
      end
      credentials.s3_options
    end

    def check_credential_provider(message)
      cr = CredentialResolvers::S3CredentialResolver.new(message, credential_provider)
      credentials = cr.destination_credentials
      if credentials.blank?
        raise ArgumentError.new("credentials not found for uri")
      end
      credentials.s3_options
    end

    # Check that I have a path
    def check_s3_uri(uri)
      if uri.bucket.blank?
        log(:error, "transport_gateway.s3_adapter") { "both bucket and file name must be provided" }
        raise URI::InvalidComponentError.new("both bucket and file name must be provided")
      end
      if uri.key.blank?
        log(:error, "transport_gateway.s3_adapter") { "both bucket and file name must be provided" }
        raise URI::InvalidComponentError.new("both bucket and file name must be provided")
      end
    end
  end
end
