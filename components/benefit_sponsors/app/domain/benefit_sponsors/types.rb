# frozen_string_literal: true

# require 'uri'
require 'cgi'
require 'dry-types'

module Types
  send(:include, Dry.Types())
  include Dry::Logic
end
