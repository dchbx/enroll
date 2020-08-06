# frozen_string_literal: true

module Forms
  module EmployerFields
    def self.included(base)
      base.class_eval do
        attr_accessor :dba, :legal_name, :entity_kind
      end
    end
  end
end
