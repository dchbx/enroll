module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationFactory

      attr_accessor :benefit_sponsorship

      def self.call(benefit_sponsorship, args)
        new(benefit_sponsorship, args).benefit_application
      end

      def self.validate(benefit_application)
        # TODO: Add validations
        # Validate open enrollment period
        true
      end

      def initialize(benefit_sponsorship, args)
        @benefit_sponsorship = benefit_sponsorship
        @benefit_application = benefit_sponsorship.benefit_applications.new
        assign_application_attributes(args)
        @benefit_application.pull_benefit_sponsorship_attributes
      end

      def benefit_application
        @benefit_application
      end

      protected

      def assign_application_attributes(args)
        return nil if args.blank?
        args.each_pair do |k, v|
          @benefit_application.send("#{k}=".to_sym, v)
        end
      end
    end

    class BenefitApplicationFactoryError < StandardError; end
  end
end
