# frozen_string_literal: true

module BenefitSponsors
  module Serializers
    class IssuerDatatableSerializer
      include FastJsonapi::ObjectSerializer

      attributes :legal_name, :products_url

      attribute :products_url do |object|
        products_url(object)
      end

      attribute :phone do |object|
        retrieve_info(object.legal_name)[0]
      end

      attribute :email do |object|
        retrieve_info(object.legal_name)[1]
      end

      attribute :working_hours do |object|
        retrieve_info(object.legal_name)[2]
      end

      class << self

        delegate :url_helpers, to: :'Rails.application.routes'

        def products_url(object)
          url_helpers.exchanges_issuer_products_path(object.issuer_profile.id)
        end

        # This needs to be updated once we start saving carrier contact info data in db.
        def retrieve_info(legal_name)
          {
            "Aetna" => ['1-855-586-6959', '', 'from 8am-6pm EST, Monday - Friday'],
            "BestLife" => ['1-800-433-0088', '', ''],
            "CareFirst" => ['1-855-444-3119', '', ''],
            "Delta Dental" => ['1-800-872-0500', '', ''],
            "Dentegra" => ['1-800-471-0284', '', ''],
            "Dominion" => ['1-855-224-3016', '', ''],
            "Kaiser Permanente" => ['1-800-777-7902', '', ''],
            "MetLife" => ['1-855-638-2221', '', ''],
            "UnitedHealthcare" => ['1-888-842-4571', '', '']
          }[legal_name] || []
        end
      end
    end
  end
end
