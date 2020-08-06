# frozen_string_literal: true

module Queries
  module People
    class PrimaryAgentsQuery
      include Enumerable

      def each
        person_query.each do |pers|
          yield pers if pers.is_active
        end
      end

      def each_with_index
        i = 0
        person_query.each do |pers|
          if pers.is_active
            yield pers, i
            i += 1
          end
        end
      end

      def policy_class
        AngularAdminApplicationPolicy
      end

      protected

      def person_query
        Person.where({
                       "$or" => [
                         {"broker_role._id" => {"$ne" => nil}},
                         {"general_agency_staff_roles.is_primary" => true}
]
                     }).without(:history_tracks, :versions, :consumer_role, :resident_role, :employee_roles, :verification_types, :documents, :employer_staff_roles, :hbx_staff_role, :csr_role, :addresses, :assister_role, :person_relationships, :encrypted_ssn, :individual_market_transistions, :inbox, :phones, :date_of_death, :employer_contact_id, :modifier_id, :ethnicity, :no_dc_address, :no_dc_address_reason, :modifier_id, :no_ssn, :tracking_version, :tribal_id, :updated_by, :updated_by_id)
      end
    end
  end
end