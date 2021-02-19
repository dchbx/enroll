module Effective
  module Datatables
    class BrokerAgencyPlanDesignOrganizationDatatable < ::Effective::MongoidDatatable
      include Config::AcaModelConcern

      datatable do

        bulk_actions_column do
           bulk_action 'Assign General Agency', "#", id: "bulk_action_assign"
           bulk_action 'Clear General Agency', sponsored_benefits.fire_organizations_general_agency_profiles_path(broker_agency_profile_id: attributes[:profile_id]),
            data: { confirm: 'Are you sure to clear general agency to the selected Employers?' }
        end

        table_column :legal_name, :label => 'Legal Name', :proc => Proc.new { |row|
          if row.broker_relationship_inactive?
            row.legal_name
          else
            (link_to row.legal_name, eval(benefit_sponsor_home_url(row)))
          end
        }, :sortable => false, :filter => false
        table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| er_fein(row) }, :sortable => false, :filter => false
        table_column :ee_count, :label => 'EE Count', :proc => Proc.new { |row| ee_count(row) }, :sortable => false, :filter => false
        table_column :er_state, :label => 'ER State', :proc => Proc.new { |row| er_state(row) }, :sortable => false, :filter => false
        table_column :effective_date, :label => 'Effective Date', :proc => Proc.new { |row|

          latest_plan_year = row.employer_profile.latest_plan_year if row.employer_profile.present?
          if latest_plan_year.blank?
            "No Active Plan"
          else
            latest_plan_year.start_on.strftime("%m/%d/%Y")
          end
        }, :sortable => false, :filter => false

        table_column :broker, :label => 'Broker', :proc => Proc.new { |row| broker_name(row) }, :sortable => false, :filter => false


        table_column :general_agency, :label => "General Agency", :proc => Proc.new { |row|
          general_agency_account = row.general_agency_accounts.active.first
          if general_agency_account
            general_agency_account.legal_name
          end
        }, :sortable => false, :filter => false

        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
            ['View Quotes', sponsored_benefits.organizations_plan_design_organization_plan_design_proposals_path(row, profile_id: attributes[:profile_id]), 'ajax'],
            ['Create Quote', sponsored_benefits.new_organizations_plan_design_organization_plan_design_proposal_path(row, profile_id: attributes[:profile_id]), 'static'],
            ['Edit Employer Details', sponsored_benefits.edit_organizations_plan_design_organization_path(row, profile_id: attributes[:profile_id]), edit_employer_link_type(row)],
            ['Show/Add Roles', benefit_sponsors.profiles_employers_employer_staff_roles_path(profile_id: row.sponsor_profile_id, employer_actions_id: "plan_design_#{row.id}"), 'ajax'],
            ['Remove Employer', sponsored_benefits.organizations_plan_design_organization_path(row),
                              remove_employer_link_type(row),
                              "Are you sure you want to remove this employer?"],
            ['Assign General Agency', sponsored_benefits.organizations_general_agency_profiles_path(id: row.id, broker_agency_profile_id: attributes[:profile_id], action_id: "plan_design_#{row.id.to_s}"), 'ajax'],
            ['Clear General Agency', sponsored_benefits.fire_organizations_general_agency_profiles_path(ids: [row.id], broker_agency_profile_id: attributes[:profile_id]),
              'post ajax with confirm',
              "Are you sure to clear General Agency for this Employer?"
            ]
          ]

          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "plan_design_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false
      end

      def remove_employer_link_type(employer)
        if employer.is_prospect?
          'delete with confirm'
        else
          return 'disabled'
        end
      end

      def edit_employer_link_type(employer)
        employer.is_prospect? ? 'ajax' : 'disabled'
      end

      def add_roles_link_type(allow)
        feature_enabled = ::EnrollRegistry.feature_enabled?(:manage_account_functionality)
        policy_accepted_and_allow = feature_enabled && allow
        policy_accepted_and_allow ? 'ajax' : 'disabled'
      end

      def broker_name(row)
        row.broker_agency_profile.primary_broker_role.person.full_name
      end

      def ee_count(row)
        return 'N/A' if row.is_prospect? || row.broker_relationship_inactive?
        row.employer_profile.roster_size
      end

      def er_state(row)
        return 'N/A' if row.is_prospect?
        return 'Former Client' if row.broker_relationship_inactive?
        sponsorship = row.employer_profile.organization.active_benefit_sponsorship
        benefit_application_summarized_state(sponsorship.dt_display_benefit_application) if sponsorship.dt_display_benefit_application.present?
      end

      def benefit_application_summarized_state(benefit_application)
        return if benefit_application.nil?
        aasm_map = {
          :draft => :draft,
          :enrollment_open => :enrolling,
          :enrollment_eligible => :enrolled,
          :binder_paid => :enrolled,
          :approved => :published,
          :pending => :publish_pending
        }

        renewing = benefit_application.predecessor_id.present? && [:active, :terminated, :termination_pending].exclude?(benefit_application.aasm_state) ? "Renewing" : ""
        summary_text = aasm_map[benefit_application.aasm_state] || benefit_application.aasm_state
        summary_text = "#{renewing} #{summary_text.to_s.humanize.titleize}"
        summary_text.strip
      end

      def er_fein(row)
        return 'N/A' if row.is_prospect? || row.broker_relationship_inactive?
        row.fein
      end

      def benefit_sponsor_home_url(row)
        "benefit_sponsors.profiles_employers_employer_profile_path(row.sponsor_profile_id, tab: 'home')"
      end

      def dc?
        aca_state_abbreviation == "DC"
      end

      def on_general_agency_portal?
        attributes[:is_general_agency?]
      end

      def collection
        return @collection if (defined? @collection) && @collection.present?
        @collection = Queries::PlanDesignOrganizationQuery.new(attributes)
      end

      def global_search?
        true
      end

      def global_search_method
        :datatable_search
      end

      def nested_filter_definition
        {
          filters:[
                { scope: 'all', label: 'All'},
                { scope: 'active_sponsors', label: 'Active'},
                { scope: 'inactive_sponsors', label: 'Inactive'},
                { scope: 'prospect_sponsors', label: "Prospects" }
              ],
          top_scope: :filters
        }
      end
    end
  end
end
