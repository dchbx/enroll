# frozen_string_literal: true

module FinancialAssistance
  module Locations
    class Email
      include Mongoid::Document
      include Mongoid::Timestamps

      #include Validations::Email

      embedded_in :applicant, class_name: '::FinancialAssistance::Applicant'

      KINDS = %w[home work].freeze

      field :kind, type: String, default: ''
      field :address, type: String

      #validates :address, :email => true, :allow_blank => false
      validates_presence_of  :kind, message: "Choose a type"
      validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid email type"

      validates :address, presence: true

      def blank?
        address.blank?
      end

      def match(another_email)
        return false if another_email.nil?
        attrs_to_match = [:kind, :address]
        attrs_to_match.all? { |attr| attribute_matches?(attr, another_email) }
      end

      def attribute_matches?(attribute, other)
        self[attribute] == other[attribute]
      end

    end
  end
end
