# frozen_string_literal: true

class BrokerStaffSerializer
  include FastJsonapi::ObjectSerializer
  attributes :first_name, :last_name
  attribute :emails, serializer: EmailSerializer
end
