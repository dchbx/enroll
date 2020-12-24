# frozen_string_literal: true

# Action cable channel for processing bulk notices
class BulkNoticeProcessingChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'bulk-notice-processing'
  end

  def receive(data)
    puts data["message"]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
