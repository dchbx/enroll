module BenefitMarkets
  module Factories
    class BenefitMarket
      def self.build
        benefit_market = BenefitMarkets::BenefitMarket.new
        aca_shop_configuration = BenefitMarkets::Factories::AcaShopConfiguration.build
        aca_individual_configuration = BenefitMarkets::Factories::AcaIndividualConfiguration.build
        [benefit_market, aca_shop_configuration, aca_individual_configuration]
      end

      def self.call(description:, kind:, site_urn:, title:, configuration:, site_id:)
        BenefitMarkets::BenefitMarket.new description: description, 
          site_id: site_id,
          kind: kind,
          site_urn: site_urn,
          title: title,
          configuration: configuration
      end

      def self.validate(benefit_market)
        benefit_market.valid?
      end
    end
  end
end