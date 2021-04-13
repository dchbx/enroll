require_dependency "benefit_sponsors/application_controller"

module BenefitSponsors
  module Profiles
    module GeneralAgencies
      class GeneralAgencyProfilesController < ::BenefitSponsors::ApplicationController
        # include Acapi::Notifiers
        include DataTablesAdapter
        include BenefitSponsors::Concerns::ProfileRegistration

        rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

        before_action :find_general_agency_profile, only: [:employers, :family_index]
        before_action :find_general_agency_staff, only: [:edit_staff, :update_staff]
        before_action :set_current_portal, only: [:show]

        layout 'single_column'

        def show
          authorize self
          set_flash_by_announcement
          @general_agency_profile = ::BenefitSponsors::Organizations::GeneralAgencyProfile.find(params[:id])
          @provider = current_user.person
        end

        def new_general_agency_profile
          authorize User, :add_roles?
          @person_id = params[:person_id]
          @agency = BenefitSponsors::Operations::GeneralAgencies::New.new.call({person_id: params[:person_id], profile_type: params[:profile_type], regitration_params: registration_params}).value!
          respond_to do |format|
            format.html
          end
        end

        def create_ga_profile
          authorize User, :add_roles?
          result = EnrollRegistry[:ga_registration] { registration_params.to_h }
          if result.success?
            redirection_url, _status = result.value!
            flash[:notice] = 'Thank you for submitting your request to access the general agency account. Your application for access is pending'
            redirect_to redirection_url
          else
            redirect_to new_general_agency_profile_profiles_general_agencies_general_agency_profiles_path(person_id: registration_params[:person_id], profile_type: registration_params[:profile_type])
          end
        end

        def employers
          authorize self
          @datatable = Effective::Datatables::BenefitSponsorsGeneralAgencyDataTable.new({id: params[:id]})
        end

        def staffs # re-check this action & uncomment spec
          authorize self
          @general_agency_profile = ::BenefitSponsors::Organizations::GeneralAgencyProfile.find(params[:format])
          @staffs = @general_agency_profile.general_agency_staff_roles
        end

        def edit_staff
          authorize self
          respond_to do |format|
            format.js
            format.html
          end
        end

        def update_staff
          authorize self
          if params['approve']
            @staff.approve!
            flash[:notice] = "Staff approved successfully."
          elsif params['deny']
            @staff.deny!
            flash[:notice] = "Staff deny."
          elsif params['decertify']
            @staff.decertify!
            flash[:notice] = "Staff decertify."
          end
          send_secure_message_to_general_agency(@staff) if @staff.active?

          redirect_to benefit_sponsors.profiles_general_agencies_general_agency_profile_path(@staff.general_agency_profile)
        end

        def redirect_to_show(general_agency_profile_id)
          redirect_to benefit_sponsors.profiles_general_agencies_general_agency_profile_path(id: general_agency_profile_id)
        end

        def families
          authorize self
          @datatable = Effective::Datatables::BenefitSponsorsGeneralAgencyFamilyDataTable.new({id: params[:id]})
        end

        def messages
          @sent_box = true
          @general_agency_profile = ::BenefitSponsors::Organizations::GeneralAgencyProfile.find(params[:id])
          @provider = @general_agency_profile
        end

        def agency_messages
        end

        def inbox
          @sent_box = true
          id = params["id"]||params['profile_id']
          @general_agency_provider = BenefitSponsors::Organizations::GeneralAgencyProfile.find(id)
          @folder = (params[:folder] || 'Inbox').capitalize
          if current_user.person._id.to_s == id
            @provider = current_user.person
          else
            @provider = @general_agency_provider
          end
        end

        private

        def send_secure_message_to_general_agency(staff_role)
          hbx_admin = HbxProfile.all.first
          general_agency = staff_role.general_agency_profile

          subject = "Received new general agency - #{staff_role.person.full_name}"
          body = "<br><p>Following are staff details<br>Staff Name : #{staff_role.person.full_name}<br>Staff NPN  : #{staff_role.npn}</p>"
          secure_message(hbx_admin, general_agency, subject, body)
        end

        def secure_message(from_provider, to_provider, subject, body)
          message_params = {
            sender_id: from_provider.id,
            parent_message_id: to_provider.id,
            from: from_provider.legal_name,
            to: to_provider.legal_name,
            subject: subject,
            body: body
          }

          create_secure_message(message_params, to_provider, :inbox)
          create_secure_message(message_params, from_provider, :sent)
        end

        def create_secure_message(message_params, inbox_provider, folder)
          message = Message.new(message_params)
          message.folder =  Message::FOLDER_TYPES[folder]
          msg_box = inbox_provider.inbox
          msg_box.post_message(message)
          msg_box.save
        end

        def find_general_agency_profile(id = nil)
          organizations = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => id)
          @general_agency_profile = organizations.first.general_agency_profile if organizations.present?
          # authorize @general_agency_profile, :access_to_broker_agency_profile?
        end

        def find_general_agency_staff
          @staff = GeneralAgencyStaffRole.find(params[:id])
        end

        def registration_params
          current_user_id = Person.find(params[:person_id]).user&.id if params[:manage_portals] && params[:person_id]
          current_user_id ||= current_user.present? ? current_user.id : nil
          params[:agency] ||= {}
          params[:agency].merge!({:profile_id => params["id"], :current_user_id => current_user_id, :person_id => params["person_id"]})
          params[:agency].permit!
        end

        def user_not_authorized(exception)
          return redirect_to main_app.new_user_registration_path unless current_user
          if current_user.has_general_agency_staff_role?
            redirect_to profiles_general_agencies_general_agency_profile_path(:id => current_user.person.general_agency_staff_roles.first.benefit_sponsors_general_agency_profile_id)
          else
            redirect_to benefit_sponsors.new_profiles_registration_path(:profile_type => :general_agency)
          end
        end
      end
    end
  end
end
