
module Effective
  module Datatables
    class SepTypeDataTable < Effective::MongoidDatatable
      include Config::AcaModelConcern
      datatable do
        table_column :title, :label => 'Title', :proc => Proc.new { |row| row.title}, :filter => false, :sortable => true
        table_column :Market, :label => 'Market', :proc => Proc.new { |row| row.market_kind}, :filter => false, :sortable => false
        table_column :start_date, :label => 'Start Date', :proc => Proc.new { |row| row.start_on }, :filter => false, :sortable => false
        table_column :state, :label => 'State', :proc => Proc.new { |row| row.is_active ? 'active' : 'Inactive'}, :filter => false, :sortable => false
      end

      def collection
        unless  (defined? @qles) && @qles.present?   #memoize the wrapper class to persist @search_string
          @qles = Queries::SepTypeDatatableQuery.new(attributes)
        end
        @qles
      end

      def global_search?
        true
      end

      def nested_filter_definition
        manage_qles_tab = [
          {scope: 'all', label: 'All'},
          {scope: 'shop_qles', label: 'SHOP', subfilter: :employer_options},
          {scope: 'fehb_qles', label: 'Congress', subfilter: :congress_options}
        ]
        if individual_market_is_enabled?
         manage_qles_tab.insert(1, {scope: 'ivl_qles', label: 'Individual', subfilter: :individual_options})
        end

        {
        employer_options: [
          {scope: 'all', label: 'All'},
          {scope: 'shop_active_qles', label: 'Active'},
          {scope: 'shop_inactive_qles', label: 'Inactive'},
          {scope: 'shop_draft_qles', label: 'Draft'}
        ],
        congress_options: [
          {scope: 'all', label: 'All'},
          {scope: 'fehb_active_qles', label: 'Active'},
          {scope: 'fehb_inactive_qles', label: 'Inactive'},
          {scope: 'fehb_draft_qles', label: 'Draft'}
        ],
        individual_options: [
          {scope: 'all', label: 'All'},
          {scope: 'ivl_active_qles', label: 'Active'},
          {scope: 'ivl_inactive_qles', label: 'Inactive'},
          {scope: 'ivl_draft_qles', label: 'Draft'}
        ],
        manage_qles: manage_qles_tab,
        top_scope: :manage_qles
        }
      end
    end
  end
end