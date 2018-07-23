module SponsoredBenefits
  module BenefitApplications
    class BenefitApplicationBuilder

      attr_reader :benefit_application

      def initialize(options)
        @application_class ||= AcaShopDcBenefitApplication
        @benefit_application = @application_class.new(options)
      end

      def add_benefit_sponsor(new_benefit_sponsor)
        @benefit_application.benefit_sponsor = new_benefit_sponsor
      end

      def add_roster(new_roster)
        @benefit_application.roster = new_roster
      end

      def add_marketplace_kind(new_marketplace_kind)
        @benefit_application.marketplace_kind = new_marketplace_kind
      end

      def add_broker(new_broker)
        @benefit_application.broker = new_broker
      end

      def add_geographic_rating_areas(new_geographic_rating_areas)
        @benefit_application.geographic_rating_areas << new_geographic_rating_areas
      end

      # Date range beginning on coverage effective date and ending on coverage expiration date
      def add_application_period(new_application_period)
        @benefit_application.application_period = new_application_period
      end

      def add_benefit_package(new_benefit_package)
        @benefit_application.benefit_packages << new_benefit_package
      end

      def benefit_application
        @benefit_application
      end

      def reset
        @benefit_application = @application_class.new(options)
      end
    end
  end
end
