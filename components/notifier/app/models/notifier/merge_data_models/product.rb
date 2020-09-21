# frozen_string_literal: true

module Notifier
  module MergeDataModels
    class Product
      include Virtus.model

      attribute :coverage_start_on, Date
      attribute :coverage_end_on, Date
      attribute :title, String
      attribute :metal_level_kind, String
      attribute :kind, String
      attribute :issuer_profile_name, String
      attribute :hsa_eligibility, Boolean
      attribute :renewal_plan_type, String
      attribute :is_csr, Boolean
      attribute :deductible, String
      attribute :family_deductible, String
      attribute :carrier_phone, String


      def self.stubbed_object
        date = TimeKeeper.date_of_record.beginning_of_year
        Notifier::MergeDataModels::Product.new(
          {
            coverage_start_on: date,
            coverage_end_on: date.next_year.prev_day,
            title: 'Aetna HSA',
            metal_level_kind: 'Gold',
            kind: :health,
            issuer_profile_name: 'Aetna',
            hsa_eligibility: false,
            renewal_plan_type: 'CFNONHSA',
            is_csr: false,
            deductible: '34.98',
            family_deductible: '44.90',
            carrier_phone: '5739383938'
          }
        )
      end
    end
  end
end