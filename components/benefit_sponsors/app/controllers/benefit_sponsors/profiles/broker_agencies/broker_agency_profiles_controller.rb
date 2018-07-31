require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  module Profiles
    module BrokerAgencies
      class BrokerAgencyProfilesController < ::BenefitSponsors::ApplicationController
        # include Acapi::Notifiers
        include DataTablesAdapter
        include BenefitSponsors::Concerns::ProfileRegistration

        rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

        before_action :set_current_person, only: [:staff_index]
        before_action :check_and_download_commission_statement, only: [:download_commission_statement, :show_commission_statement]

        layout 'single_column'

        EMPLOYER_DT_COLUMN_TO_FIELD_MAP = {
          "2"     => "legal_name",
          "4"     => "employer_profile.aasm_state",
          "5"     => "employer_profile.plan_years.start_on"
        }

        def index
          authorize self
          @broker_agency_profiles = BenefitSponsors::Organizations::Organization.broker_agency_profiles.map(&:broker_agency_profile)
        end

        def show
          authorize self, :redirect_signup?
          set_flash_by_announcement
          @broker_agency_profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id])
          @provider = current_user.person
        end

        def staff_index
          authorize self
          @q = params.permit(:q)[:q]
          @staff = eligible_brokers
          @page_alphabets = page_alphabets(@staff, "last_name")
          page_no = cur_page_no(@page_alphabets.first)
          if @q.nil?
            @staff = @staff.where(last_name: /^#{page_no}/i)
          else
            @staff = @staff.where(last_name: /^#{@q}/i)
          end
        end

        # TODO need to refactor for cases around SHOP broker agencies
        def family_datatable
          authorize self
          find_broker_agency_profile(BSON::ObjectId.from_string(params.permit(:id)[:id]))
          dt_query = extract_datatable_parameters

          query = BenefitSponsors::Queries::BrokerFamiliesQuery.new(dt_query.search_string, @broker_agency_profile.id)
          @total_records = query.total_count
          @records_filtered = query.filtered_count
          @families = query.filtered_scope.skip(dt_query.skip).limit(dt_query.take).to_a
          primary_member_ids = @families.map do |fam|
            fam.primary_family_member.person_id
          end
          @primary_member_cache = {}
          Person.where(:_id => { "$in" => primary_member_ids }).each do |pers|
            @primary_member_cache[pers.id] = pers
          end

          @draw = dt_query.draw
        end

        def family_index
          authorize self
          find_broker_agency_profile(BSON::ObjectId.from_string(params.permit(:id)[:id]))
          @q = params.permit(:q)[:q]

          respond_to do |format|
            format.js {}
          end
        end

        def commission_statements
          permitted = params.permit(:id)
          @id = permitted[:id]
          if current_user.has_broker_role?
            find_broker_agency_profile(current_user.person.broker_role.broker_agency_profile_id)
          elsif current_user.has_hbx_staff_role?
            find_broker_agency_profile(BSON::ObjectId.from_string(@id))
          else
            redirect_to new_profiles_registration_path
            return
          end
          documents = @broker_agency_profile.documents
          if documents
            @statements = get_commission_statements(documents)
          end
          collect_and_sort_commission_statements
          respond_to do |format|
            format.js
          end
        end

        def show_commission_statement
          options={}
          options[:filename] = @commission_statement.title
          options[:type] = 'application/pdf'
          options[:disposition] = 'inline'
          send_data Aws::S3Storage.find(@commission_statement.identifier) , options
        end

        def download_commission_statement
          options={}
          options[:content_type] = @commission_statement.type
          options[:filename] = @commission_statement.title
          send_data Aws::S3Storage.find(@commission_statement.identifier) , options
        end

        def employers
        end

        #TODO Implement when we move GeneralAgencyProfile in Engine.
        def general_agency_index
        end

        def set_default_ga
        end

        def employer_datatable
        end

        def assign
        end

        def update_assign
        end

        def clear_assign_for_employer
        end

        def assign_history
        end

        def manage_employers
        end

        def messages
          @sent_box = true
          # don't use current_user
          # messages are different for current_user is admin and broker account login
          @broker_agency_profile = ::BenefitSponsors::Organizations::BrokerAgencyProfile.find(params[:id])
          @broker_provider = @broker_agency_profile.primary_broker_role.person

          respond_to do |format|
            format.js {}
          end
        end

        def agency_messages
        end

        def inbox
          @sent_box = true
          id = params["id"]||params['profile_id']
          @broker_agency_provider = find_broker_agency_profile(BSON::ObjectId(id))
          @folder = (params[:folder] || 'Inbox').capitalize
          if current_user.person._id.to_s == id
            @provider = current_user.person
          else
            @provider = @broker_agency_provider
          end
        end

        private

        def check_and_download_commission_statement
          @broker_agency_profile = BenefitSponsors::Organizations::Profile.find(params[:id])
          authorize @broker_agency_profile, :access_to_broker_agency_profile?
          @commission_statement = @broker_agency_profile.documents.find(params[:statement_id])
        end

        def find_broker_agency_profile(broker_agency_profile_id = nil)
          id = broker_agency_profile_id || BSON::ObjectId(params[:id])
          organizations = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => id)
          @broker_agency_profile = organizations.first.broker_agency_profile if organizations.present?
          authorize @broker_agency_profile, :access_to_broker_agency_profile?
        end

        def user_not_authorized(exception)
          if exception.query == :redirect_signup?
            redirect_to main_app.new_user_registration_path
          elsif current_user.has_broker_agency_staff_role?
            redirect_to profiles_broker_agencies_broker_agency_profile_path(:id => current_user.person.broker_agency_staff_roles.first.benefit_sponsors_broker_agency_profile_id)
          else
            redirect_to benefit_sponsors.new_profiles_registration_path(:profile_type => :broker_agency)
          end
        end

        def send_general_agency_assign_msg(general_agency, employer_profile, status)
        end

        def eligible_brokers
          Person.where('broker_role.broker_agency_profile_id': {:$exists => true}).where(:'broker_role.aasm_state'=> 'active').any_in(:'broker_role.market_kind'=>[person_market_kind, "both"])
        end

        def update_ga_for_employers(broker_agency_profile, old_default_ga=nil)
        end

        def person_market_kind
          if @person.has_active_consumer_role?
            "individual"
          elsif @person.has_active_employee_role?
            "shop"
          end
        end

        def check_general_agency_profile_permissions_assign
        end

        def check_general_agency_profile_permissions_set_default
        end

        def get_commission_statements(documents)
          commission_statements = []
          documents.each do |document|
            # grab only documents that are commission statements by checking the bucket in which they are placed
            if document.identifier.include?("commission-statements")
              commission_statements << document
            end
          end
          commission_statements
        end

        def collect_and_sort_commission_statements(sort_order='ASC')
          @statement_years = (Settings.aca.shop_market.broker_agency_profile.minimum_commission_statement_year..TimeKeeper.date_of_record.year).to_a.reverse
          @statements.sort_by!(&:date).reverse!
        end
      end
    end
  end
end
