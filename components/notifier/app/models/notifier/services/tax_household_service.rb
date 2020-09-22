# frozen_string_literal: true

#Taxhousehold service for Final Eligibility Notice

module Notifier
  module Services
    class TaxHouseholdService

      include Notifier::ConsumerRoleHelper

      def initialize(member)
        @primary_member = member
        @csr_percent_as_integer = csr_percent_as_integer
        @max_aptc = max_aptc
        @aptc_csr_annual_household_income = aptc_csr_annual_household_income
        @aptc_csr_monthly_household_income = aptc_csr_monthly_household_income
        @aptc_annual_income_limit = aptc_annual_income_limit
        @csr_annual_income_limit = csr_annual_income_limit
        @applied_aptc = applied_aptc
      end

      attr_accessor :csr_percent_as_integer, :max_aptc, :aptc_csr_annual_household_income
      attr_accessor :primary_member, :aptc_csr_monthly_household_income, :aptc_annual_income_limit
      attr_accessor :csr_annual_income_limit, :applied_aptc, :primary_member

      private

      def csr_percent_as_integer
        primary_member["csr"].present? && primary_member["csr"].upcase == "YES" ? primary_member["csr_percent"] : "100"
      end

      def max_aptc
        primary_member["aptc"].presence || 0.0
      end

      def aptc_csr_annual_household_income
        primary_member["actual_income"].presence || nil
      end

      def aptc_csr_monthly_household_income
        primary_member["monthly_hh_income"].presence || nil
      end

      def aptc_annual_income_limit
        primary_member["aptc_annual_limit"].presence || nil
      end

      def csr_annual_income_limit
        primary_member["csr_annual_income_limit"].presence || nil
      end

      def applied_aptc
        primary_member["applied_aptc"].presence || 0.0
      end

      def format_currency(val)
        val.to_f.round(2)
      end
    end
  end
end
