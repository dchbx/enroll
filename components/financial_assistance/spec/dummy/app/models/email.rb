# frozen_string_literal: true

class Email
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person
  embedded_in :office_location

  field :kind, type: String
  field :address, type: String
end
