require 'openssl'
require 'net/http'

module TransportGateway
  class Adapters::HttpAdapter
    include ::TransportGateway::Adapters::Base

    def send_message(message)
      target_uri  = message.to
      source      = message.from
      body        = message.body

      payload = select_payload(source, body)
      put_request = request_for(target_uri, payload)

      http_site = Net::HTTP.new(target_uri.host, target_uri.port)
      http_site.request(put_request)
    end

  private

    def select_payload(source, body)
      return source if (source.present? && source.is_a?(File))
      return body if body.present?
      nil
    end

    def request_for(uri, content)
      request = Net::HTTP::Put.new(uri.path)
      request.basic_auth(uri.user, uri.password) unless uri.userinfo.blank?

      request_content_type_for(request, content)
    end

    def request_content_type_for(request, content)
      case content
       when File 
        request.set_content_type('text/plain')
        request.body_stream = content
      when String
        request.set_content_type('text/plain')
        request.body = content
      when nil
        request.body = nil
      else
        request.body = content
      end

      request
    end

  end
end
