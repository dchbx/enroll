module TransportGateway
  class Adapters::FileAdapter
    include ::TransportGateway::Adapters::Base
    
    def receive_message(message)
      if message.from.blank?
        log(:error, "transport_gateway.file_adapter") { "source file not provided" }
        raise ArgumentError.new "source file not provided" 
      end
      Sources::FileSource.new(URI.decode(message.from.path))
    end

    def send_message(message)
      if message.to.blank?
        log(:error, "transport_gateway.file_adapter") { "destination not provided" }
        raise ArgumentError.new "destination not provided"
      end
      # Allow empty string sources
      if (message.from.blank? && (message.body == nil))
        log(:error, "transport_gateway.file_adapter") { "source file not provided" }
        raise ArgumentError.new "source file not provided"
      end
      to_path = URI.decode(message.to.path)

      ensure_directory_for(to_path)
      source = provide_source_for(message)
      begin
      File.open(to_path, 'wb') do |f|
        in_stream = source.stream
        while data = in_stream.read(4096) do
          f.write(data)
        end
      end
      ensure
        source.cleanup
      end
    end

    protected

    def provide_source_for(message)
      unless message.body.blank?
        return Sources::StringIOSource.new(message.body)
      end
      gateway.receive_message(message)
    end


    def ensure_directory_for(path)
      dir = File.dirname(path)
      return nil if File.exists?(dir)
      FileUtils.mkdir_p(dir)
    end

  end
end
