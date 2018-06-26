# module SponsoredBenefits
  module Effective
    module Datatables
      class BrokerAgencyEmployerDatatable < ::Effective::MongoidDatatable
        include Config::AcaModelConcern

        datatable do
          if individual_market_is_enabled?
            bulk_actions_column do
            end
          end 
          table_column :legal_name, :label => 'Legal Name', :proc => Proc.new { |row|
            if row.broker_relationship_inactive?
              row.legal_name
            else
              (link_to row.legal_name, main_app.employers_employer_profile_path(id: row.sponsor_profile_id, :tab=>'home'))
            end
            }, :sortable => false, :filter => false
          table_column :fein, :label => 'FEIN', :proc => Proc.new { |row| er_fein(row) }, :sortable => false, :filter => false
          table_column :ee_count, :label => 'EE Count', :proc => Proc.new { |row| ee_count(row) }, :sortable => false, :filter => false
          table_column :er_state, :label => 'ER State', :proc => Proc.new { |row| er_state(row) }, :sortable => false, :filter => false
          table_column :effective_date, :label => 'Effective Date', :proc => Proc.new { |row|

            active_plan_year_start = row.try(:employer_profile).try(:latest_plan_year).try(:start_on)
            if active_plan_year_start.nil?
              "No Active Plan"
            else
              active_plan_year_start
            end

            }, :sortable => false, :filter => false

          table_column :broker, :label => 'Broker', :proc => Proc.new { |row|
              if general_agency_enabled?
                 person_record = row.broker_agency_profile.primary_broker_role.person
                 redirect_path = main_app.edit_broker_agencies_profile_applicant_path(row.broker_agency_profile, person_record)
                 link_to row.broker_agency_profile.primary_broker_role.person.full_name, redirect_path
              else
                 broker_name(row)
               end
            }, :sortable => false, :filter => false
          
          if attributes["general_agency_is_enabled"]
              table_column :general_agency, :label => "General Agency", :proc => Proc.new { |row| 
              if row.general_agency_profile
                 general_agency_profiles = row.general_agency_profile
                 broker_agency_profile = row.broker_agency_profile
                 ga_legal_name = general_agency_profiles.legal_name
                 clear_assign_path =  raw('<br>') + link_to( "#{l10n('clear_assignment')}", main_app.clear_assign_for_employer_broker_agencies_profile_path(id: broker_agency_profile.id, employer_id: row.employer_profile.id), method: :post, remote: true, data: {  confirm: l10n("broker_agencies.profiles.remove_general_agency_assignment") })
                 general_agency = ga_legal_name + clear_assign_path if ga_legal_name
              end
            }, :sortable => false, :filter => false

           end

          unless attributes["general_agency_is_enabled"]
            table_column :actions, :width => '50px', :proc => Proc.new { |row|
              dropdown = [
               # Link Structure: ['Link Name', link_path(:params), 'link_type'], link_type can be 'ajax', 'static', or 'disabled'
               ['View Quotes', sponsored_benefits.organizations_plan_design_organization_plan_design_proposals_path(row), 'ajax'],
               ['Create Quote', sponsored_benefits.new_organizations_plan_design_organization_plan_design_proposal_path(row), 'static'],
               ['Edit Employer Details', sponsored_benefits.edit_organizations_plan_design_organization_path(row), edit_employer_link_type(row)],
               ['Remove Employer', sponsored_benefits.organizations_plan_design_organization_path(row),
                                  remove_employer_link_type(row),
                                  "Are you sure you want to remove this employer?"]
              ]
              render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "employers_actions_#{row.id.to_s}"}, formats: :html
            }, :filter => false, :sortable => false
          end
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

        def broker_name(row)
          row.broker_agency_profile.primary_broker_role.person.full_name
        end

        scopes do
          scope :legal_name, "Hello"
        end

        def ee_count(row)
          return 'N/A' if row.is_prospect? || row.broker_relationship_inactive?
          row.employer_profile.roster_size
        end

        def er_state(row)
          return 'N/A' if row.is_prospect?
          return 'Former Client' if row.broker_relationship_inactive?
          row.employer_profile.aasm_state.capitalize
        end

        def er_fein(row)
          return 'N/A' if row.is_prospect? || row.broker_relationship_inactive?
          row.fein
        end

        class << self
        	attr_accessor :profile_id
        end

        def collection
          unless (defined? @employers) && @employers.present?
            @employers = Queries::PlanDesignOrganizationQuery.new(attributes)
          end
          @employers
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
          else
            super
          end
        end

        def nested_filter_definition
          {
            sponsors:[
                  { scope: 'all', label: 'All'},
                  { scope: 'active_sponsors', label: 'Active'},
                  { scope: 'inactive_sponsors', label: 'Inactive'},
                  { scope: 'prospect_sponsors', label: "Prospects" }
                ],
            top_scope: :sponsors
          }
        end


      end
    end
  end
# end
