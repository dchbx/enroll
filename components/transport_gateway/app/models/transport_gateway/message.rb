require 'uri'

module TransportGateway
  class Message

    attr_accessor :from, :to, :body

    attr_accessor :source_credentials, :destination_credentials

    #  @from
    #  @to 
    #  @body

    ## ACApi attributes
    #  @hbx_id
    #  @submitted_timestamp
    #  @authorization
    #  @service_status_type
    #  @message_id
    #  @originating_service
    #  @reply_to
    #  @fault_to
    #  @correlation_id
    #  @application_header_properties

    def initialize(**options)
      parse_options(options) unless options.empty?

      # Target must be a URI
      @to = to_uri(options[:to])
    end

    def log_inspect()
      <<-LOGSTRING
        From: #{from.to_s}
        To: #{to.to_s}
        #{log_body}
      LOGSTRING
    end

  private

    def log_body
      return("------- NIL BODY VALUE ------") if body.nil?
      if body.respond_to?(:size)
        if body.size > 1024
          "------- Large body > 1024 bytes -------"
        else
          body.to_s
        end
      end
    end

    def to_uri(value)
      return if value.nil?
      value.is_a?(URI) ? value : URI.parse(value.to_s)
    end

    def parse_options(options)
      options.each { |k,v| instance_variable_set("@#{k}", v) }
    end

  end
end
