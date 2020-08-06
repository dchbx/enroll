# frozen_string_literal: true

module Forms
  module NpnField
    def self.included(base)
      base.class_eval do
        attr_reader :npn

        def npn=(new_npn)
          @npn = new_npn.to_s.gsub(/\D/, '') unless new_npn.blank?
        end
      end
    end
  end
end