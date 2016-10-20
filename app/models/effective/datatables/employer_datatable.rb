
module Effective
  module Datatables
    class EmployerDatatable < Effective::MongoidDatatable
      datatable do


        bulk_actions_column do
           bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { confirm: 'Generate Invoices?', no_turbolink: true }
           bulk_action 'Mark Binder Paid', binder_paid_exchanges_hbx_profiles_path, data: {  confirm: 'Mark Binder Paid?', no_turbolink: true }
           #bulk_action 'Transmit Group XML', transmit_group_xml_exchanges_hbx_profiles_path, data: {  confirm: 'Transmit Group XML?', no_turbolink: true }
        end

        table_column :legal_name, :proc => Proc.new { |row| link_to row.legal_name.titleize, employers_employer_profile_path(row.employer_profile, :tab=>'home')}, :sortable => false, :filter => false
        table_column :hbx_id, :width => '100px', :proc => Proc.new { |row| truncate(row.id.to_s, length: 8, omission: '' ) }, :sortable => false, :filter => false
        table_column :fein, :width => '100px', :proc => Proc.new { |row| row.fein }, :sortable => false, :filter => false
        table_column :plan_year_status, :width => '120px', :proc => Proc.new { |row| row.employer_profile.renewing_plan_year.present? ? 'Renewing' : 'New'}, :filter => false
        table_column :eligibility, :proc => Proc.new { |row| eligibility_criteria(row.employer_profile) }, :filter => false
        table_column :broker, :proc => Proc.new { |row|
            row.employer_profile.broker_agency_profile.organization.legal_name.titleize if row.employer_profile.broker_agency_profile.present?
          }, :filter => false
        table_column :general_agency, :proc => Proc.new { |row|
          row.employer_profile.active_general_agency_legal_name.titleize if row.employer_profile.active_general_agency_legal_name.present?
        }, :filter => false
        table_column :conversion, :width => '120px', :proc => Proc.new { |row| boolean_to_glyph(row.employer_profile.is_conversion?)}, :filter => {include_blank: false, :as => :select, :collection => ['All','Yes', 'No'], :selected => 'All'}

        table_column :plan_year_state, :proc => Proc.new { |row| row.employer_profile.try(:latest_plan_year).try(:aasm_state).try(:titleize)}, :filter => false
        table_column :invoiced, :proc => Proc.new { |row| boolean_to_glyph(row.current_month_invoice.present?)}, :filter => false
        #table_column :update_at, :proc => Proc.new { |row| row[5].strftime('%m/%d/%Y')}
        table_column :hi, :proc => Proc.new { |row| "Hello"}
        table_column :transmit_xml, :proc => Proc.new { |row|
          #link_to('Transmit XML', transmit_group_xml_exchanges_hbx_profile_path(row.employer_profile), method: :post, data: { confirm: group_xml_transmitted_message(row.employer_profile) })
          link_to('Transmit XML', transmit_group_xml_exchanges_hbx_profile_path(row.employer_profile), method: :post)
        }

      end


      def collection
        employers = Organization.all_employer_profiles


        if attributes[:employers].present? && !['all'].include?(attributes[:employers])
          employers = employers.send(attributes[:enrolling]) if attributes[:enrolling].present?
          employers = employers.send(attributes[:enrolling_initial]) if attributes[:enrolling_initial]
          employers = employers.send(attributes[:enrolling_renewing]) if attributes[:enrolling_renewing]

          employers = employers.send(attributes[:enrolled]) if attributes[:enrolled].present?
          employers = employers.send(attributes[:employers]) if !attributes[:enrolled].present? && !attributes[:enrolling].present?
        end

        employers

      end

      def global_search?
        true
      end

      def search_column(collection, table_column, search_term, sql_column)
        if table_column[:name] == 'legal_name'
          collection.datatable_search(search_term)
        elsif table_column[:name] == 'fein'
          collection.datatable_search_fein(search_term)
        elsif table_column[:name] == 'conversion'
          if search_term == "Yes"
            collection.datatable_search_employer_profile_source("conversion")
          elsif search_term == "No"
            collection.datatable_search_employer_profile_source("self_serve")
          else
            super
          end
        else
          super
        end
      end

      def nested_filter_definition

        filters = {
        enrolling_renewing:
          [
            {scope: 'employer_profiles_renewing_application_pending', label: 'Application Pending'},
            {scope: 'employer_profiles_renewing_open_enrollment', label: 'Open Enrollment'},
          ],
        enrolling_initial:
          [
            {scope: 'employer_profiles_initial_application_pending', label: 'Application Pending'},
            {scope: 'employer_profiles_initial_open_enrollment', label: 'Open Enrollment'},
            {scope: 'employer_profiles_binder_pending', label: 'Binder Pending'},
            {scope: 'employer_profiles_binder_paid', label: 'Binder Paid'},
          ],
        enrolled:
          [
            {scope:'employer_profiles_enrolled', label: 'All' },
            {scope:'employer_profiles_suspended', label: 'Suspended' },
          ],
        enrolling:
          [
            {scope:'employer_profiles_enrolling', label: 'All'},
            {scope:'employer_profiles_initial_eligible', label: 'Initial', subfilter: :enrolling_initial},
            {scope:'employer_profiles_renewing', label: 'Renewing / Converting', subfilter: :enrolling_renewing},
            #['', 'Ineligible', :enrolling_ineligible],
          ],
        employers:
         [
           {scope:'all', label: 'All'},
           {scope:'employer_profiles_applicants', label: 'Applicants'},
           {scope:'employer_profiles_enrolling', label: 'Enrolling', subfilter: :enrolling},
           {scope:'employer_profiles_enrolled', label: 'Enrolled', subfilter: :enrolled},
         ],
        top_scope: :employers
        }

      end
    end
  end
end
