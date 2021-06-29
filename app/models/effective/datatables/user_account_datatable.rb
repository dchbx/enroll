# frozen_string_literal: true

module Effective
  module Datatables
    class UserAccountDatatable < Effective::MongoidDatatable
      include Config::SiteModelConcern

      datatable do
        table_column :name, :label => 'USERNAME', :proc => proc { |row| row.oim_id }, :filter => false, :sortable => true
        table_column :ssn, :label => 'SSN', :proc => proc { |row| truncate(number_to_obscured_ssn(row.person.ssn)) if row.person.present? }, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => proc { |row| format_date(row.person.dob) if row.person.present?}, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => proc { |row| row.person.hbx_id if row.person.present?}, :filter => false, :sortable => false
        table_column :email, :label => 'USER EMAIL', :proc => proc { |row| row.email }, :filter => false, :sortable => false
        table_column :status, :label => 'Status', :proc => proc { |row| status(row) }, :filter => false, :sortable => false
        table_column :role_type, :label => 'Role Type', :proc => proc { |row| row.roles.join(', ') }, :filter => false, :sortable => false
        table_column :permission, :label => 'Permission level', :proc => proc { |row| permission_type(row) }, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => proc { |row|
                                                            dropdown = [
                                                                # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
                                                                if row.email.present?
                                                                  ['Reset Password', reset_password_user_path(row), 'ajax']
                                                                else
                                                                  ['Reset Password', edit_user_path(row.id), 'ajax']
                                                                end,
                                                                ['Unlock / Lock Account', confirm_lock_user_path(row.id, user_action_id: "user_action_#{row.id}"), 'ajax'],
                                                                ['View Login History',login_history_user_path(id: row.id), 'ajax'],
                                                                ['Edit User', change_username_and_email_user_path(row.id, user_id: row.id.to_s), 'ajax']
                                                            ]
                                                            render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "user_action_#{row.id}"}, formats: :html
                                                          }, :filter => false, :sortable => false
      end

      def collection
        @user_collection = Queries::UserDatatableQuery.new(attributes) unless (defined? @user_collection) && @user_collection.present? #memoize the wrapper class to persist @search_string
        @user_collection
      end

      def status(row)
        return "Unlocked" if row.locked_at.blank? && row.unlock_token.blank?
        "Locked"
      end

      def permission_type(row)
        row&.person&.hbx_staff_role&.permission&.name || 'N/A'
      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
      end

      def nested_filter_definition
        {
          lock_unlock:
              [
                {scope: 'locked', label: 'Locked'},
                {scope: 'unlocked', label: 'Unlocked'}
              ],
          users:
              [{scope: 'all', label: 'All', subfilter: :lock_unlock}].tap do |a|
                a << {scope: 'all_employee_roles', label: 'Employee', subfilter: :lock_unlock} if is_shop_or_fehb_market_enabled?
                a << {scope: 'all_employer_staff_roles', label: 'Employer', subfilter: :lock_unlock} if is_shop_or_fehb_market_enabled?
                a << {scope: 'all_broker_roles', label: 'Broker', subfilter: :lock_unlock}
                a << {scope: 'all_consumer_roles', label: 'Consumer', subfilter: :lock_unlock}
              end,
          top_scope: :users
        }
      end
    end
  end
end
