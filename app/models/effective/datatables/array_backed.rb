
module Effective
  module Datatables
    class ArrayBacked < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
           bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { method: :post, confirm: 'Generate Invoices?' }
        end

        table_column :legal_name, :width => '200px', :proc => Proc.new { |row| link_to row.legal_name.titleize, employers_employer_profile_path(row.employer_profile, :tab=>'home')}
        table_column :hbx_id, :width => '100px', :proc => Proc.new { |row| truncate(row.id.to_s, length: 8, omission: '' ) }
        table_column :fein, :width => '100px', :proc => Proc.new { |row| row.fein }
        table_column :plan_year_status, :proc => Proc.new { |row| row.employer_profile.renewing_plan_year.present? ? 'Renewing' : 'New'}
        table_column :conversion,:proc => Proc.new { |row| boolean_to_glyph(row.employer_profile.is_conversion?)}, :filter => false, :sortable => true
        table_column :state,:proc => Proc.new { |row| row.primary_office_location.try(:address).try(:state)} , :filter => false, :sortable => false
        table_column :plan_year_state,:proc => Proc.new { |row| row.employer_profile.try(:latest_plan_year).try(:aasm_state)}
        #table_column :update_at, :proc => Proc.new { |row| row[5].strftime('%m/%d/%Y')}


      end

      scopes do
        scope :legal_name, "Hello"
      end

      def collection
        employers = Organization.all_employer_profiles
      end

      def global_search?
        true
      end


    end
  end
end
