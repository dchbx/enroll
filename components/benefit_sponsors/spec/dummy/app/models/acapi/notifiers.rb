module Acapi
  module Notifiers
    def notify(event_name, payload = {})
      ActiveSupport::Notifications.instrument(event_name, payload)
    end
  end
end
