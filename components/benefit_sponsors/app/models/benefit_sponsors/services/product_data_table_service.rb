# frozen_string_literal: true

module BenefitSponsors
  module Services
    class ProductDataTableService
      attr_accessor :issuer_profile_id, :filter, :key, :value

      def initialize(params = {})
        @issuer_profile_id = params[:issuer_profile_id]
        @filter = params[:filter].to_h
        @key, @value = @filter&.first
      end

      def legal_name
        Rails.cache.fetch("#{issuer_profile_id}_legal_name", expires_in: 2.days) do
          BenefitSponsors::Organizations::ExemptOrganization.by_profile_id(issuer_profile_id).first.legal_name
        end
      end

      def all?
        filter.empty? || value == "nil"
      end

      def filtered_plans
        today = TimeKeeper.date_of_record
        current_year = today.year
        years = [current_year, current_year - 1]
        (10..12).cover?(today.month) ? (years << current_year + 1) : years
      end

      def retrieve_table_data
        records = ::BenefitMarkets::Products::Product.by_issuer_profile_id(issuer_profile_id).across_years(filtered_plans)
        records = all? ? records : records.send(key, value)
        records.sort_by(&:active_year).reverse!
      end
    end
  end
end
