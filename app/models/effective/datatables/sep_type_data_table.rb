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
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
              #TODO pundit policy
              ['Publish', sep_type_to_publish_exchanges_manage_sep_types_path(qle_id: row.id, qle_action_id: "sep_type_actions_#{row.id.to_s}"),
               publish_sep_type(row, pundit_allow(Family, :can_update_ssn?)) ],
              ['Expire', sep_type_to_expire_exchanges_manage_sep_types_path(qle_id: row.id, qle_action_id: "sep_type_actions_#{row.id.to_s}"),
               expire_sep_type(row, pundit_allow(Family, :can_update_ssn?)) ]
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "sep_type_actions_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def collection
        @qles = Queries::SepTypeDatatableQuery.new(attributes)
      end

      def global_search?
        true
      end

      def publish_sep_type(qle, allow)
        return 'disabled' unless allow  #TODO pundit policy
        qle.draft? ? 'ajax' : 'disabled'
      end

      def expire_sep_type(qle, allow)
        return 'disabled' unless allow  #TODO pundit policy
        (qle.can_be_expire_pending? || qle.can_be_expired?) ? 'ajax' : 'disabled' # TODO fix DB aasm_states.
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