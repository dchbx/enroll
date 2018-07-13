module BenefitSponsors
  module Queries
    class BrokerApplicantsDatatableQuery

      attr_reader :search_string, :custom_attributes

      def datatable_search(string)
        @search_string = string
        self
      end

      def initialize(attributes)
        @custom_attributes = attributes
      end

      def person_search search_string
        ::Person.exists(broker_role: true).broker_role_having_agency if search_string.blank?
      end

      def build_scope()
        person = ::Person.exists(broker_role: true).broker_role_having_agency.order_by(created_at: :desc)
        person
      end

      def skip(num)
        build_scope.skip(num)
      end

      def limit(num)
        build_scope.limit(num)
      end

      def order_by(var)
        @order_by = var
        self
      end

      def klass
        ::Person.exists(broker_role: true).broker_role_having_agency
      end

      def size
        build_scope.count
      end

    end
  end
end
