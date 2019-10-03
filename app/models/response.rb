# frozen_string_literal: true

class Response
  include Mongoid::Document

  embedded_in :custom_qle_answer

  field :name, type: String
  field :operator, type: String
  field :value, type: Date
  field :value_2, type: Date

  field :result, type: Symbol
end
