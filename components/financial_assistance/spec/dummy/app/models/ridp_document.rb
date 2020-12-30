# frozen_string_literal: true

class RidpDocument
  include Mongoid::Document
  include Mongoid::Timestamps
  RIDP_DOCUMENT_KINDS = ['Driver License'].freeze
end
