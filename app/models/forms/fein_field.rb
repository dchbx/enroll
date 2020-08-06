# frozen_string_literal: true

module Forms
  module FeinField
    def self.included(base)
      base.class_eval do
        attr_reader :fein

        def fein=(new_fein)
          @fein = new_fein.to_s.gsub(/\D/, '') unless new_fein.blank?
        end
      end
    end
  end
end
