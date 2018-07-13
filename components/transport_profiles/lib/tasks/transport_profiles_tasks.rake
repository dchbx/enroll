namespace :transport_profiles do
  desc "List endpoints used by processes"
  task :process_endpoints => :environment do
    Dir[File.join(::TransportProfiles::Engine.root, 'app/models/**/*.rb')].each do |path|
        require path
    end
    ::TransportProfiles::Processes::Process.descendants.each do |desc_kls|
      puts desc_kls.to_s
      print "  "
      print desc_kls.used_endpoints.join("\n  ")
      print "\n\n"
    end
  end

  desc "List context name references used by processes"
  task :process_context_names => :environment do
    Dir[File.join(::TransportProfiles::Engine.root, 'app/models/**/*.rb')].each do |path|
        require path
    end
    ::TransportProfiles::Processes::Process.descendants.each do |desc_kls|
      puts desc_kls.to_s
      print "  "
      print desc_kls.used_context_names.join("\n  ")
      print "\n\n"
    end
  end

  desc "List all referenced endpoints and who references them"
  task :endpoint_references => :environment do
    Dir[File.join(::TransportProfiles::Engine.root, 'app/models/**/*.rb')].each do |path|
        require path
    end
    endpoint_references = Hash.new { |h, k| h[k] = Array.new }
    ::TransportProfiles::Processes::Process.descendants.each do |desc_kls|
      used_endpoints = desc_kls.used_endpoints
      used_endpoints.each do |ue|
        endpoint_references[ue] = endpoint_references[ue] + [desc_kls.to_s]
      end
    end
    endpoint_references.keys.sort.each do |k|
      puts "#{k}"
      print "  "
      puts(endpoint_references[k].sort.uniq.join("\n  "))
      print "\n"
    end
  end

  desc "Verify referenced endpoints have been specified"
  task :verify_endpoints => :environment do
    Dir[File.join(::TransportProfiles::Engine.root, 'app/models/**/*.rb')].each do |path|
        require path
    end
    endpoint_references = Hash.new { |h, k| h[k] = Array.new }
    ::TransportProfiles::Processes::Process.descendants.each do |desc_kls|
      used_endpoints = desc_kls.used_endpoints
      used_endpoints.each do |ue|
        endpoint_references[ue] = endpoint_references[ue] + [desc_kls.to_s]
      end
    end
    endpoint_references.keys.sort.each do |k|
      endpoint_results = ::TransportProfiles::WellKnownEndpoint.find_by_endpoint_key(k)
      if endpoint_results.count < 1
        puts "Missing Endpoint: #{k}"
        puts "  Referenced by:" 
        endpoint_references[k].uniq.each do |ref|
          puts "    - #{ref}"
        end
        puts "\n"
      elsif endpoint_results.count > 1
        puts "Overloaded endpoint: #{k} found #{endpoint_results.count} times"
        puts "  Referenced by:" 
        endpoint_references[k].uniq.each do |ref|
          puts "    - #{ref}"
        end
        puts "\n"
      end
    end
  end
end
