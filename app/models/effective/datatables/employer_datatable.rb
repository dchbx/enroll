module Effective
  module Datatables
    class EmployerDatatable < Effective::MongoidDatatable
      include Config::AcaModelConcern
      datatable do

        bulk_actions_column(partial: 'datatables/employers/bulk_actions_column') do
           bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { confirm: 'Generate Invoices?', no_turbolink: true }
           bulk_action 'Mark Binder Paid', binder_paid_exchanges_hbx_profiles_path, data: {  confirm: 'Mark Binder Paid?', no_turbolink: true }
        end

        table_column :legal_name, :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          (link_to row.legal_name.titleize, employers_employer_profile_path(@employer_profile, :tab=>'home'))

          }, :sortable => false, :filter => false
        #table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| truncate(row.id.to_s, length: 8, omission: '' ) }, :sortable => false, :filter => false
        table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| row.fein }, :sortable => false, :filter => false
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| row.hbx_id }, :sortable => false, :filter => false
#        table_column :eligibility, :proc => Proc.new { |row| eligibility_criteria(@employer_profile) }, :filter => false
        table_column :broker, :proc => Proc.new { |row|
            @employer_profile.try(:active_broker_agency_legal_name).try(:titleize) #if row.employer_profile.broker_agency_profile.present?
          }, :filter => false
        table_column :general_agency, :proc => Proc.new { |row|
          @employer_profile.try(:active_general_agency_legal_name).try(:titleize) #if row.employer_profile.active_general_agency_legal_name.present?
        }, :filter => false
        table_column :conversion, :proc => Proc.new { |row| boolean_to_glyph(@employer_profile.is_conversion?)}, :filter => {include_blank: false, :as => :select, :collection => ['All','Yes', 'No'], :selected => 'All'}

        table_column :plan_year_state, :proc => Proc.new { |row|
          if @employer_profile.present?
            @latest_plan_year = @employer_profile.dt_display_plan_year
            @latest_plan_year.aasm_state.titleize if @latest_plan_year.present?
          end }, :filter => false
        table_column :effective_date, :proc => Proc.new { |row|
          @latest_plan_year.try(:start_on)
          }, :filter => false, :sortable => true
        table_column :invoiced?, :proc => Proc.new { |row| boolean_to_glyph(row.current_month_invoice.present?)}, :filter => false
        # table_column :participation, :proc => Proc.new { |row| @latest_plan_year.try(:employee_participation_percent)}, :filter => false
        # table_column :enrolled_waived, :label => 'Enrolled/Waived', :proc => Proc.new { |row|
        #   [@latest_plan_year.try(:enrolled_summary), @latest_plan_year.try(:waived_summary)].compact.join("/")
        #   }, :filter => false, :sortable => false
        table_column :xml_submitted, :label => 'XML Submitted', :proc => Proc.new {|row| format_time_display(@employer_profile.xml_transmitted_timestamp)}, :filter => false, :sortable => false
        if employer_attestation_is_enabled?
          table_column :attestation_status, :label => 'Attestation Status', :proc => Proc.new {|row| row.employer_profile.employer_attestation.aasm_state.titleize if row.employer_profile.employer_attestation }, :filter => false, :sortable => false
        end
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
           ['Transmit XML', transmit_group_xml_exchanges_hbx_profile_path(row.employer_profile), @employer_profile.is_transmit_xml_button_disabled? ? 'disabled' : 'static'],
           ['Generate Invoice', generate_invoice_exchanges_hbx_profiles_path(ids: [row]), generate_invoice_link_type(row)],
          ]
          if individual_market_is_enabled?
            people_id = Person.where({"employer_staff_roles.employer_profile_id" => row.employer_profile._id}).map(&:id)
            dropdown.insert(2,['View Username and Email', get_user_info_exchanges_hbx_profiles_path(
              people_id: people_id,
              employers_action_id: "employer_actions_#{@employer_profile.id}"
              ), !people_id.empty? && pundit_allow(Family, :can_view_username_and_email?) ? 'ajax' : 'disabled'])
          end

          if employer_attestation_is_enabled?
            dropdown.insert(2,['Attestation', edit_employers_employer_attestation_path(id: row.employer_profile.id, employer_actions_id: "employer_actions_#{@employer_profile.id}"), 'ajax'])
          end

          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "employer_actions_#{@employer_profile.id}"}, formats: :html
        }, :filter => false, :sortable => false

      end

      def generate_invoice_link_type(row)
        row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        return @employer_collection if defined? @employer_collection
        employers = Organization.all_employer_profiles
        if attributes[:employers].present? && !['all'].include?(attributes[:employers])
          employers = employers.send(attributes[:employers]) if ['employer_profiles_applicants','employer_profiles_enrolling','employer_profiles_enrolled', 'employer_attestations'].include?(attributes[:employers])
          employers = employers.send(attributes[:enrolling]) if attributes[:enrolling].present?
          employers = employers.send(attributes[:enrolling_initial]) if attributes[:enrolling_initial].present?
          employers = employers.send(attributes[:enrolling_renewing]) if attributes[:enrolling_renewing].present?
          employers = employers.send(attributes[:enrolled]) if attributes[:enrolled].present?
          employers = employers.send(attributes[:attestations]) if attributes[:attestations].present?

          if attributes[:upcoming_dates].present?
              if date = Date.strptime(attributes[:upcoming_dates], "%m/%d/%Y")
                employers = employers.employer_profile_plan_year_start_on(date)
              end
          end

        end


        @employer_collection = employers

      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
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
        @next_30_day = TimeKeeper.date_of_record.next_month.beginning_of_month
        @next_60_day = @next_30_day.next_month
        @next_90_day = @next_60_day.next_month

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
          upcoming_dates:
            [
              {scope: @next_30_day, label: @next_30_day },
              {scope: @next_60_day, label: @next_60_day },
              {scope: @next_90_day, label: @next_90_day },
              #{scope: "employer_profile_plan_year_start_on('#{@next_60_day})'", label: @next_60_day },
              #{scope: "employer_profile_plan_year_start_on('#{@next_90_day})'",  label: @next_90_day },
            ],
        enrolling:
          [
            {scope: 'employer_profiles_enrolling', label: 'All'},
            {scope: 'employer_profiles_initial_eligible', label: 'Initial', subfilter: :enrolling_initial},
            {scope: 'employer_profiles_renewing', label: 'Renewing / Converting', subfilter: :enrolling_renewing},
            {scope: 'employer_profiles_enrolling', label: 'Upcoming Dates', subfilter: :upcoming_dates},
          ],
         attestations:
          [
            {scope: 'employer_attestations', label: 'All'},
            {scope: 'employer_attestations_submitted', label: 'Submitted'},
            {scope: 'employer_attestations_pending', label: 'Pending'},
            {scope: 'employer_attestations_approved', label: 'Approved'},
            {scope: 'employer_attestations_denied', label: 'Denied'},
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
        if employer_attestation_is_enabled?
          filters[:employers] << {scope:'employer_attestations', label: 'Employer Attestations', subfilter: :attestations}
        end
        filters
      end
    end
  end
end
