module Enrollments
  module Replicator

    class Base
      attr_accessor :base_enrollment, :new_effective_date

      def initialize(base_enrollment, new_effective_date)
        @base_enrollment = base_enrollment
        @new_effective_date = new_effective_date
      end

      def build
        replication_type = determine_replication_type

        replication_instance = if replication_type == :reinstatement
          Reinstatement.new(base_enrollment, new_effective_date)
        elsif replication_type == :renewal
          base_enrollment.is_shop? ? ShopMarketRenewal.new(base_enrollment, new_effective_date)
            : IndividualMarketRenewal.new(base_enrollment, new_effective_date)
        else
          raise StandardError, 'Please verify effective date. Request is not a re-instatement/renewal.'
        end

        replication_instance.build
      end
    end
  end
end