# frozen_string_literal: true

class EmailSerializer
  include FastJsonapi::ObjectSerializer
  attributes :adddress
end
