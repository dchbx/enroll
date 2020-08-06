# frozen_string_literal: true

module Effective
  module Datatables
    class BrokerApplicantsDataTable < ::Effective::MongoidDatatable
      datatable do
        table_column :name, :label => 'Applicant Name', :proc => proc { |row| row.full_name }, :filter => false, :sortable => false
        table_column :npn, :label => 'Applicant NPN', :proc => proc { |row| row.broker_role.npn }, :filter => false, :sortable => false
        table_column :agency_name, :label => 'Agency Name', :proc => proc { |row| row.broker_role.try(:broker_agency_profile).try(:legal_name) }, :filter => false, :sortable => false
        table_column :status, :label => 'Status', :proc => proc { |row| row.broker_role.current_state }, :filter => false, :sortable => false
        table_column :submitted_date, :label => 'Submitted Date', :proc => proc { |row| format_datetime row.broker_role.latest_transition_time }, :filter => false, :sortable => false

      end

      def collection
        @people = BenefitSponsors::Queries::BrokerApplicantsDatatableQuery.new(attributes) unless (defined? @people) && @people.present?
        @people
      end

      def global_search?
        true
      end

      def broker_agency_profile(row)
        row.broker_role.broker_agency_profile
      end

      def def(nested_filter_definition); end
    end
  end
end
