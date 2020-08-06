# frozen_string_literal: true

module Listeners
  class IndividualResourceListener < ::Acapi::Amqp::Client
    def initialize(ch, q)
      super(ch, q)
      @controller = Events::IndividualsController.new
    end

    def self.queue_name
      config = Rails.application.config.acapi
      "#{config.hbx_id}.#{config.environment_name}.q.#{config.app_id}.individual_resource_listener"
    end

    def on_message(delivery_info, properties, payload)
      @controller.resource(connection,delivery_info, properties, payload)
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def self.run
      conn = Bunny.new(Rails.application.config.acapi.remote_broker_uri, :heartbeat => 15)
      conn.start
      ch = conn.create_channel
      ch.prefetch(1)
      q = ch.queue(queue_name, :durable => true)

      self.new(ch, q).subscribe(:block => true, :manual_ack => true)
      conn.close
    end
  end
end
