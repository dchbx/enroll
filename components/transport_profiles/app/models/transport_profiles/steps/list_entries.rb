module TransportProfiles
  # List the entries of a remote resource and store the results in a process context, optionally filtering them.
  class Steps::ListEntries < Steps::Step
    
    # Iniitialize the listing step.
    # @param endpoint_key [Symbol] a key representing the name of the endpoint to query
    # @param result_key [Symbol] the name to use to store the results in the process context
    # @param gateway [TransportGateway::Gateway] the transport gateway instance to use for moving of resoruces
    # @param t_blk [Block] (optional) an optional block that will filter the returned results.  When omitted, all results will be returned.
    # @yieldparam entries [Array<TransportGateway::ResourceEntry>] list of returned entries
    # @yieldparam context [TransportProfile::ProcessContext] (optional) the process context
    # @yieldreturn [Array<TransportGateway::ResourceEntry>] The list of entries to keep
    def initialize(endpoint_key, result_key, gateway, &t_blk)
      super("List Entries at: #{endpoint_key}, store as: #{result_key}", gateway)
      @endpoint_key = endpoint_key
      @storage_key = result_key
      @transform_blk = t_blk
    end

    # @!visibility private
    def execute(process_context)
      endpoints = ::TransportProfiles::WellKnownEndpoint.find_by_endpoint_key(@endpoint_key)
      raise ::TransportProfiles::EndpointNotFoundError unless endpoints.size > 0
      raise ::TransportProfiles::AmbiguousEndpointError, "More than one matching endpoint found" if endpoints.size > 1
      endpoint = endpoints.first
      query = TransportGateway::ResourceQuery.new({
        from: URI.parse(endpoint.uri),
        source_credentials: endpoint
      })
      entries = @gateway.list_entries(query)
      matching_entries = if !@transform_blk.nil?
                           @transform_blk.call(entries, process_context)
                         else
                           entries
                         end
      process_context.put(@storage_key, matching_entries.map(&:uri))
    end
  end
end
