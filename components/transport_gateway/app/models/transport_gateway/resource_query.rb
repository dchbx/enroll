module TransportGateway
  class ResourceQuery
    attr_accessor :from, :source_credentials

    def initialize(**options)
      parse_options(options) unless options.empty?

      @from = to_uri(options[:from])
    end

    def to_uri(value)
      return if value.nil?
      value.is_a?(URI) ? value : URI.parse(value.to_s)
    end

    def parse_options(options)
      options.each { |k,v| instance_variable_set("@#{k}", v) }
    end

    def log_inspect
      <<-LOGSTRING
        From: #{from.to_s}
      LOGSTRING
    end
  end
end
