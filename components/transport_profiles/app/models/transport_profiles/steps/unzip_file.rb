module TransportProfiles
  module Steps
    # Unzips a source file into a set of temporary files.
    class UnzipFile < Step
      # Create a new step which will unzip a resource.
      # @param file_name [URI, Symbol] represents the path of the resource being transported.
      #   If a URI, is the URI of the source resource.
      #   If a Symbol, represents a URI or collection of URIs stored in the process context.
      # @param files_key [Symbol] the process context key under which to store the URIs representing the locations of the unzipped files
      # @param temp_directory_key [Symbol] the process context key under which to store the paths of the temporary directory created to hold the unzipped files. These will be automatically removed at the end of the process.
      # @param gateway [TransportGateway::Gateway] the transport gateway instance to use for moving of resoruces
      # @param source_credentials [Symbol, TransportProfiles::Credential] Optional.  Specifies the credentials for the source resources when needed.  This is usually used when your source is a collection of multiple resources.
      #   If a symbol, is the key of an endpoint, which is then used to resolve the credentials.
      #   If an instance of {TransportProfiles::Credential}, is used directly.
      def initialize(file_name, files_key, temp_directory_key, gateway, source_credentials: nil)
        super("Unzip from: #{file_name}", gateway)
        @files_key = files_key
        @file_name = file_name
        @source_credentials = resolve_source_credentials(source_credentials)
        @temp_directory_key = temp_directory_key
      end
      
      # @!visibility private
      def execute(process_context)
        source_uris = resolve_message_sources(process_context)


        source_uris.each do |file_uri|
          message = ::TransportGateway::Message.new(from: file_uri, source_credentials: @source_credentials)

          tmp_dir = Dir.mktmpdir
          process_context.remember_to_clean_up(tmp_dir)
          process_context.update(@temp_directory_key, []) do |dir_list|
            dir_list + [tmp_dir]
          end
          temp_stream = @gateway.receive_message(message)
          Zip::InputStream.open(temp_stream.stream) do |io|
            while (entry = io.get_next_entry)
              if entry.name_is_directory?
                output_name = File.join(tmp_dir, entry.name)
                FileUtils.mkdir_p(output_name)
              end
            end
          end
          temp_stream.stream.rewind
          Zip::InputStream.open(temp_stream.stream) do |io|
            while (entry = io.get_next_entry)
              if !entry.name_is_directory?
                output_name = File.join(tmp_dir, entry.name)
                entry.extract(output_name)
                process_context.update(@files_key, []) do |f_list|
                  f_list + [URI.join("file://", URI.escape(output_name))]
                end
              end
            end
          end
          temp_stream.cleanup
        end
      end

      # @!visibility private
      def resolve_source_credentials(source_credentials)
        return source_credentials unless source_credentials.kind_of?(Symbol)
        endpoints = ::TransportProfiles::WellKnownEndpoint.find_by_endpoint_key(source_credentials)
        raise ::TransportProfiles::EndpointNotFoundError unless endpoints.size > 0
        raise ::TransportProfiles::AmbiguousEndpointError, "More than one matching endpoint found" if endpoints.size > 1
        endpoints.first
      end

      # @!visibility private
      def resolve_message_sources(process_context)
        found_name = @file_name.kind_of?(Symbol) ? process_context.get(@file_name) : @file_name
        if found_name.kind_of?(Array)
          found_name.map do |fn|
            fn.respond_to?(:scheme) ? fn : URI.parse(fn)
          end
        else
          found_name.respond_to?(:scheme) ? [found_name] : [URI.parse(found_name)]
        end
      end
    end
  end
end
