module Effective
  module Datatables
    class QuoteDatatable < Effective::MongoidDatatable

      datatable do
        table_column :employer_name, proc: Proc.new { |row|
        row.employer_profile.present? ? row.employer_profile.legal_name : row.employer_name
        }, :sortable => false, :filter => false
        table_column :employer_type, proc: Proc.new { |row| row.employer_type }, label: 'Employer Type', :sortable => false, :filter => false
      	table_column :quote, proc: Proc.new { |row|
      	  link_to row.quote_name.titleize, broker_agencies_broker_role_quote_path(
      	    row.broker_role_id, row),
      	  data: { no_turbolink: true }      		},
      	  :sortable => false, :filter => false
        table_column :effective_date, :proc => Proc.new { |row| row.start_on }, :filter => false
      	table_column :claim_code, proc: Proc.new { |row| row.claim_code}, :sortable => false, :filter => false
      	table_column :family_count, proc: Proc.new { |row| row.quote_households.count}, :sortable => false, :filter => false
      	table_column :state, proc: Proc.new { |row| row.aasm_state}, :sortable => false, :filter => false
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown= [
            ['Edit Roster',edit_broker_agencies_broker_role_quote_path(broker_role_id: row.broker_role_id, id: row.id),'static'],
            ['View Published Quote',publish_broker_agencies_broker_role_quotes_path(broker_role_id: row.broker_role_id, quote_id: row.id, :format => :pdf), draft_quote_publish_disabled?(row)],
            ['Delete Quote',delete_quote_broker_agencies_broker_role_quote_path(broker_role_id: row.broker_role_id, id: row.id), 'ajax'],
            ['Copy Quote',copy_broker_agencies_broker_role_quotes_path(broker_role_id: row.broker_role_id, quote_id: row.id), 'ajax'],
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "quote_actions_#{row.id.to_s}"}, formats: :html
          }, :filter => false, :sortable => false
      end

      def collection
        state = attributes['states']
        type = attributes['employer_types']
        broker_role_id = attributes["collection_scope"] || QuoteDatatable.broker_role_id.to_s
        quotes = Quote.where('broker_role_id'.to_s => broker_role_id.strip)
        quotes = quotes.where(employer_type: type) if ['client','prospect'].include?(type)
        quotes = quotes.where(aasm_state: state) if ['draft', 'published', 'claimed'].include?(state)
        quotes
      end

      def global_search?
      	true
      end

      def nested_filter_definition
        {
          top_scope:  :employer_types,
          states: [
            {scope: 'all', label: 'All'},
            {scope: 'draft', label: 'Draft'},
            {scope: 'published', label: 'Published'},
            {scope: 'claimed', label: 'Claimed'},
          ],
          employer_types: [
            {scope: 'all', label: 'All'},
            # {scope: 'client', label: 'Client', subfilter: :states},
            {scope: 'prospect', label: 'Prospect', subfilter: :states},
          ],
        }
      end

      def draft_quote_publish_disabled?(row)
        if row.aasm_state == 'draft'
          return 'disabled'
        else
          return 'static'
        end
      end

      class << self
      	attr_accessor :broker_role_id
      end

    end
  end
end
