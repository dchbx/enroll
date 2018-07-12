module TransportGateway
  # Shared resources and methods
  ADAPTER_FOLDER    = "adapters"
  CREDENTIAL_FOLDER = "credentials"
  CREDENTIAL_KINDS  = ["basic", "key"]

  class Gateway
    attr_reader :credential_provider, :logger

    def initialize(credential_provider, l_provider)
      @adapters = []
      @credential_provider = credential_provider
      @logger = l_provider
      load_adapters
    end

    def adapters
      @adapters
    end

    def list_entries(resource_query)
      logger.info("transport_gateway") { "Started resource query:\n#{resource_query.log_inspect}" }
      adapter = adapter_from(resource_query)
      adapter.assign_providers(self, credential_provider)
      adapter.add_observer(LoggingObserver.new(logger))
      adapter.list_entries(resource_query)
    end

    def receive_message(message)
      logger.info("transport_gateway") { "Started receive of message:\n#{message.log_inspect}" }
      adapter = adapter_from(message)
      adapter.assign_providers(self, credential_provider)
      adapter.add_observer(LoggingObserver.new(logger))
      adapter.receive_message(message)
    end

    def send_message(message)
      logger.info("transport_gateway") { "Started send of message:\n#{message.log_inspect}" }
      adapter = adapter_to(message)
      adapter.assign_providers(self, credential_provider)
      adapter.add_observer(LoggingObserver.new(logger))
      adapter.send_message(message)
    end

  private

    def adapter_folder
      "adapters"
    end

    def adapter_to(message)
      adapter_for_uri(message.to)
    end

    def adapter_from(message)
      adapter_for_uri(message.from)
    end

    def adapter_for_uri(uri)
      protocol = (uri.scheme == "ftp") ? "sftp" : uri.scheme

      adapter_klass = klass_for(TransportGateway::ADAPTER_FOLDER, protocol)
      if adapter_klass.nil?
        logger.error("transport_gateway") { "No Adapter found for #{uri.to_s}" }
        raise URI::BadURIError.new("unsupported scheme: #{uri.scheme}")
      end
      adapter_klass.new
    end

    def klass_for(component_folder, component_name)
      namespace_path = self.class.name.deconstantize.underscore + "/" + component_folder
      klass_name = namespace_path + '/' + component_name + '_' + component_folder.singularize
      klass_name.camelize.safe_constantize
    end

    def load_adapters
      adapter_dir = File.dirname(__FILE__)
      pattern = File.join(adapter_dir, TransportGateway::ADAPTER_FOLDER, '*.rb')

      Dir.glob(pattern).each do |file|
        require file
        @adapters << File.basename(file, '.rb').to_sym
      end
    end

    def camel_case(string)
      tokens = string.split('.') 
      tokens.map! {|t| t.capitalize}
      tokens.join('Dot')
    end

    def low_case(string)
      tokens = string.split('.')
      tokens.map! {|t| t.downcase}
      tokens.join('_dot_')
    end

  end
end
