
module Effective
  module Datatables
    class BrokerAgencyDatatable < Effective::MongoidDatatable
      datatable do


        # bulk_actions_column do
        #    bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { confirm: 'Generate Invoices?', no_turbolink: true }
        #    bulk_action 'Mark Binder Paid', binder_paid_exchanges_hbx_profiles_path, data: {  confirm: 'Mark Binder Paid?', no_turbolink: true }
        # end

        table_column :legal_name, :proc => Proc.new { |row|
          #row.legal_name
          #(link_to row.legal_name.titleize, employers_employer_profile_path(@employer_profile, :tab=>'home')) + raw("<br>") + truncate(row.id.to_s, length: 8, omission: '' )
          #link_to broker_agency_profile.legal_name, broker_agencies_profile_path(broker_agency_profile)
          link_to row.legal_name, broker_agencies_profile_path(row.broker_agency_profile)
          }, :sortable => false, :filter => false

        table_column :dba, :proc => Proc.new { |row|
          row.dba
        }, :sortable => false, :filter => false
        table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| row.fein }, :sortable => false, :filter => false

        table_column :entity_kind, :proc => Proc.new { |row| row.broker_agency_profile.entity_kind.titleize }, :sortable => false, :filter => false
        table_column :market_kind, :proc => Proc.new { |row| row.broker_agency_profile.market_kind.titleize }, :sortable => false, :filter => false

      end

      def collection
        return @broker_agency_profiles_collection if defined? @broker_agency_profiles_collection

        @broker_agency_profiles_collection = Organization.exists(broker_agency_profile: true).order_by([:legal_name])

      end

      def global_search?
        true
      end


      def search_column(collection, table_column, search_term, sql_column)
          super
      end

      def nested_filter_definition


        filters = {
        broker_agencies:
         [
           {scope:'all', label: 'All'},
         ],
        top_scope: :broker_agencies
        }

      end
    end
  end
end
