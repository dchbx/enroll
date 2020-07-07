# frozen_string_literal: true

module Effective
  module Datatables
    class SepTypeDataTable < Effective::MongoidDatatable
      include Config::AcaModelConcern
      datatable do
        table_column :title, :label => 'Title', :proc => proc { |row| row.title}, :filter => false, :sortable => true
        table_column :Market, :label => 'Market', :proc => proc { |row| row.market_kind}, :filter => false, :sortable => false
        table_column :start_date, :label => 'Start Date', :proc => proc { |row| row.start_on }, :filter => false, :sortable => false
        table_column :state, :label => 'State', :proc => proc { |row| row.is_active ? 'active' : 'Inactive'}, :filter => false, :sortable => false
      end

      def collection
        @qles = Queries::SepTypeDatatableQuery.new(attributes)
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
        manage_qles_tab.insert(1, {scope: 'ivl_qles', label: 'Individual', subfilter: :individual_options}) if individual_market_is_enabled?
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