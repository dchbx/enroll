module Effective
  module Datatables
    class BenefitSponsorsEmployerDatatable < Effective::MongoidDatatable
      include Config::AcaModelConcern

      SOURCE_KINDS = ([:all]+ BenefitSponsors::BenefitSponsorships::BenefitSponsorship::SOURCE_KINDS).freeze

      datatable do

        bulk_actions_column(partial: 'datatables/employers/bulk_actions_column') do
          bulk_action 'Generate Invoice', generate_invoice_exchanges_hbx_profiles_path, data: { confirm: 'Generate Invoices?', no_turbolink: true }
          bulk_action 'Mark Binder Paid', binder_paid_exchanges_hbx_profiles_path, data: {  confirm: 'Mark Binder Paid?', no_turbolink: true }
        end

        table_column :legal_name, :proc => Proc.new { |row|
          @employer_profile = row.organization.employer_profile
          (link_to row.organization.legal_name.titleize, benefit_sponsors.profiles_employers_employer_profile_path(@employer_profile.id, :tab=>'home'))

          }, :sortable => false, :filter => false
        table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| row.organization.fein }, :sortable => false, :filter => false
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| row.organization.hbx_id }, :sortable => false, :filter => false
        table_column :broker, :proc => Proc.new { |row|
            @employer_profile.try(:active_broker_agency_legal_name).try(:titleize) #if row.employer_profile.broker_agency_profile.present?
          }, :filter => false

        # TODO: Make this based on settings. MA does not use, but others might.
        # table_column :general_agency, :proc => Proc.new { |row|
        #   @employer_profile.try(:active_general_agency_legal_name).try(:titleize) #if row.employer_profile.active_general_agency_legal_name.present?
        # }, :filter => false

        # table_column :conversion, :proc => Proc.new { |row|
        #   boolean_to_glyph(row.is_conversion?)}, :filter => {include_blank: false, :as => :select, :collection => ['All','Yes', 'No'], :selected => 'All'}

        table_column :source_kind, :proc => Proc.new { |row|
          row.source_kind.to_s.humanize},
          :filter => {include_blank: false, :as => :select, :collection => SOURCE_KINDS, :selected => "all"}

        table_column :plan_year_state, :proc => Proc.new { |row|
          if row.latest_benefit_application.present?
            benefit_application_summarized_state(row.latest_benefit_application)
          end }, :filter => false
        table_column :effective_date, :proc => Proc.new { |row|
          if row.latest_benefit_application.present?
            row.latest_benefit_application.effective_period.min.strftime("%m/%d/%Y")
          end }, :filter => false, :sortable => true

        table_column :invoiced?, :proc => Proc.new { |row|
          boolean_to_glyph(@employer_profile.current_month_invoice.present?)}, :filter => false

        # table_column :xml_submitted, :label => 'XML Submitted', :proc => Proc.new {|row| format_time_display(@employer_profile.xml_transmitted_timestamp)}, :filter => false, :sortable => false

        if employer_attestation_is_enabled?
          table_column :attestation_status, :label => 'Attestation Status', :proc => Proc.new {|row|
            #TODO fix this after employer attestation is fixed, this is only temporary fix
            #used below condition, as employer_attestation is embedded from both employer profile and benefit sponsorship
            if row.employer_attestation.present?
              row.employer_attestation.aasm_state.titleize
            elsif @employer_profile.employer_attestation.present?
              @employer_profile.employer_attestation.aasm_state.titleize
            end
          }, :filter => false, :sortable => false
        end

        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
           # ['Transmit XML', transmit_group_xml_exchanges_hbx_profile_path(@employer_profile), @employer_profile.is_transmit_xml_button_disabled? ? 'disabled' : 'static'],
           ['Transmit XML', "#", "static"],
           ['Generate Invoice', generate_invoice_exchanges_hbx_profiles_path(ids: [@employer_profile.organization.active_benefit_sponsorship]), generate_invoice_link_type(@employer_profile)],
          ]
          # if individual_market_is_enabled?
          #   people_id = Person.where({"employer_staff_roles.employer_profile_id" => @employer_profile._id}).map(&:id)
          #   dropdown.insert(2,['View Username and Email', main_app.get_user_info_exchanges_hbx_profiles_path(
          #     people_id: people_id,
          #     employers_action_id: "employer_actions_#{@employer_profile.id}"
          #     ), !people_id.empty? && pundit_allow(Family, :can_view_username_and_email?) ? 'ajax' : 'disabled'])
          # end

          if employer_attestation_is_enabled?
            dropdown.insert(2,['Attestation', main_app.edit_employers_employer_attestation_path(id: @employer_profile.id, employer_actions_id: "employer_actions_#{@employer_profile.id}"), 'ajax'])
          end

          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "employer_actions_#{@employer_profile.id}"}, formats: :html
        }, :filter => false, :sortable => false

      end

      def generate_invoice_link_type(row)
        row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        return @employer_collection if defined? @employer_collection

        benefit_sponsorships ||= BenefitSponsors::BenefitSponsorships::BenefitSponsorship.all

        if attributes[:employers].present? && !['all'].include?(attributes[:employers])
          benefit_sponsorships = benefit_sponsorships.send(attributes[:employers]) if employer_kinds.include?(attributes[:employers])

          if attributes[:enrolling].present?
            if attributes[:enrolling_initial].present? || attributes[:enrolling_renewing].present?
              benefit_sponsorships = benefit_sponsorships.send(attributes[:enrolling_initial]) if attributes[:enrolling_initial].present? && attributes[:enrolling_initial] != 'all'
              benefit_sponsorships = benefit_sponsorships.send(attributes[:enrolling_renewing]) if attributes[:enrolling_renewing].present? && attributes[:enrolling_renewing] != 'all'
              benefit_sponsorships = benefit_sponsorships.send(attributes[:enrolling]) if attributes[:enrolling_initial].present? && attributes[:enrolling_initial] == 'all' || attributes[:enrolling_renewing].present? && attributes[:enrolling_renewing] == 'all'
            else
              benefit_sponsorships = benefit_sponsorships.send(attributes[:enrolling])
            end
          end

          benefit_sponsorships = benefit_sponsorships.send(attributes[:enrolled]) if attributes[:enrolled].present?
          benefit_sponsorships = benefit_sponsorships.send(attributes[:attestations]) if attributes[:attestations].present?


          if attributes[:upcoming_dates].present?
              if date = Date.strptime(attributes[:upcoming_dates], "%m/%d/%Y")
                benefit_sponsorships = benefit_sponsorships.effective_date_begin_on(date)
              end
          end

        end

          # if employer_attestation_kinds.include?(attributes[:attestations])
          #   benefit_sponsorships =  @benefit_sponsorships.attestations_by_kind(attributes[:attestations])
          # elsif enrolling_kinds.include?(attributes[:enrolling])
          #   benefit_sponsorships = @benefit_sponsorships.send(attributes[:enrolling])
          # elsif enrolled_kinds.include?(attributes[:enrolled])
          #   #TODO for employer enrolled kinds
          # else
          #   benefit_sponsorships = @benefit_sponsorships.send(attributes[:employers])
          # end

          # employers = @employers.send(attributes[:enrolling]) if attributes[:enrolling].present?
          # employers = employers.send(attributes[:enrolling_initial]) if attributes[:enrolling_initial].present?
          # employers = employers.send(attributes[:enrolling_renewing]) if attributes[:enrolling_renewing].present?

          # employers = employers.send(attributes[:enrolled]) if attributes[:enrolled].present?


          @employer_collection = benefit_sponsorships
      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
      end

      def employer_kinds
        ['benefit_sponsorship_applicant','benefit_application_enrolling','benefit_application_enrolled', 'employer_attestations']
      end

      def employer_attestation_kinds
        kinds ||= EmployerAttestation::ATTESTATION_KINDS
      end

      def enrolling_kinds
        []
      end

      def enrolled_kinds
        []
      end

      def search_column(collection, table_column, search_term, sql_column)
        if table_column[:name] == 'source_kind' || table_column[:name] == 'mid_plan_year_conversion'
          if search_term != "all"
            collection.datatable_search_for_source_kind(search_term.to_sym)
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
            {scope:'all', label: 'All'},
            #{scope: 'employer_profiles_renewing_application_pending', label: 'Application Pending'},
            {scope: 'benefit_application_enrolling_renewing_oe', label: 'Open Enrollment'},
            {scope: 'benefit_application_renewing_binder_paid', label: 'Binder Paid'},
          ],
        enrolling_initial:
          [
            {scope:'all', label: 'All'},
            #{scope: 'employer_profiles_initial_application_pending', label: 'Application Pending'},
            {scope: 'benefit_application_enrolling_initial_oe', label: 'Open Enrollment'},
            #{scope: 'employer_profiles_binder_pending', label: 'Binder Pending'},
            {scope: 'benefit_application_initial_binder_paid', label: 'Binder Paid'},
          ],
        enrolled:
          [
            {scope:'benefit_application_enrolled', label: 'All' },
            {scope:'benefit_application_suspended', label: 'Suspended' },
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
            {scope: 'benefit_application_enrolling', label: 'All'},
            {scope: 'benefit_application_enrolling_initial', label: 'Initial', subfilter: :enrolling_initial},
            {scope: 'benefit_application_enrolling_renewing', label: 'Renewing', subfilter: :enrolling_renewing},
            # {scope: 'employer_profiles_enrolling', label: 'Upcoming Dates', subfilter: :upcoming_dates},
            {scope: 'benefit_application_enrolling', label: 'Upcoming Dates', subfilter: :upcoming_dates},
            #{scope: 'benefit_application_imported', label: 'Converting'}
          ],
         attestations:
          [
            {scope: 'employer_attestations', label: 'All'},
            {scope: 'submitted', label: 'Submitted'},
            {scope: 'pending', label: 'Pending'},
            {scope: 'approved', label: 'Approved'},
            {scope: 'denied', label: 'Denied'},
          ],
        employers:
         [
           {scope:'all', label: 'All'},
           {scope:'benefit_sponsorship_applicant', label: 'Applicants'},

           {scope:'benefit_application_enrolling', label: 'Enrolling', subfilter: :enrolling},
           #{scope:'benefit_application_enrolling', label: 'Enrolling'},

           {scope:'benefit_application_enrolled', label: 'Enrolled', subfilter: :enrolled},
           #{scope:'benefit_application_enrolled', label: 'Enrolled'},
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
