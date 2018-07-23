module BenefitSponsors
  module Serializers
    class ProfileSerializer < ActiveModel::Serializer
      attributes :id, :contact_method, :sic_code,
                   :languages_spoken, :working_hours, :accept_new_clients, :profile_type, :market_kind_options,
                    :market_kind, :language_options, :home_page, :grouped_sic_code_options, :ach_routing_number, :ach_account_number
      attribute :contact_method_options
      # attribute :rating_area_id, if: :is_cca_employer_profile?
      attribute :sic_code, if: :is_cca_employer_profile?
      attribute :grouped_sic_code_options, if: :is_cca_employer_profile?
      attribute :languages_spoken, if: :is_broker_profile?
      attribute :working_hours, if: :is_broker_profile?
      attribute :accept_new_clients, if: :is_broker_profile?
      attribute :market_kind_options, if: :is_broker_profile?
      attribute :market_kind, if: :is_broker_profile?
      attribute :language_options, if: :is_broker_profile?
      attribute :home_page, if: :is_broker_profile?
      attribute :id, if: :is_persisted?
      attribute :ach_account_number, if: :is_broker_profile?
      attribute :ach_routing_number, if: :is_broker_profile?

      has_many :office_locations, serializer: ::BenefitSponsors::Serializers::OfficeLocationSerializer
      has_one :inbox, serializer: ::BenefitSponsors::Serializers::InboxSerializer

      def is_persisted?
        object.persisted?
      end

      def is_cca_employer_profile?
        object.kind_of?(BenefitSponsors::Organizations::AcaShopCcaEmployerProfile)
      end

      def is_dc_employer_profile?
        object.kind_of?(BenefitSponsors::Organizations::AcaShopDcEmployerProfile)
      end

      def is_employer_profile?
        is_cca_employer_profile? || is_dc_employer_profile?
      end

      def is_broker_profile?
        object.kind_of?(BenefitSponsors::Organizations::BrokerAgencyProfile)
      end

      def market_kind_options
        object.market_kinds
      end

      def contact_method_options
        object.contact_methods
      end

      def grouped_sic_code_options
        return @grouped_sic_codes if defined? @grouped_sic_codes
        @grouped_sic_codes = Caches::SicCodesCache.load
      end

      def profile_type
        str = object.class.to_s
        if str.match(/EmployerProfile/)
          "benefit_sponsor"
        elsif str.match(/BrokerAgencyProfile/)
          "broker_agency"
        end
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?

        end
        hash
      end
    end
  end
end
