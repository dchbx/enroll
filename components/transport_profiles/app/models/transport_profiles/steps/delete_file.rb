module TransportProfiles
  # Delete a local file resource.
  class Steps::DeleteFile < Steps::Step

    # Create a new step instance.
    # @param path [URI, Symbol] represents the path of the resource to delete.
    #   If a URI, is the local file URI.
    #   If a Symbol, represents a URI or collection of URIs stored in the process context.
    # @param gateway [TransportGateway::Gateway] the transport gateway instance to use for moving of resoruces
    def initialize(path, gateway)
      super("Delete file: #{path}", gateway)
      @path = path
    end

    # @!visibility private
    def resolve_files(process_context)
      found_name = @path.kind_of?(Symbol) ? process_context.get(@path) : @path
      found_name.kind_of?(Array) ? found_name : [found_name]
    end

    # @!visibility private
    def execute(process_context)
      delete_paths = resolve_files(process_context)
      delete_paths.each do |f_path|
        del_path = f_path.respond_to?(:scheme) ? URI.decode(f_path.path) : f_path
        FileUtils.rm_f(del_path)
      end
    end
  end
end
