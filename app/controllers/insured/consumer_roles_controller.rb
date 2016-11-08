class Insured::ConsumerRolesController < ApplicationController
  include ApplicationHelper
  include VlpDoc
  include ErrorBubble

  before_action :check_consumer_role, only: [:search]
  before_action :find_consumer_role, only: [:edit, :update]
  #before_action :authorize_for, except: [:edit, :update]

  def ssn_taken
  end

  def privacy
    set_current_person(required: false)
    @val = params[:aqhp] || params[:uqhp]
    @key = params.key(@val)
    @search_path = {@key => @val}
    if @person.try(:consumer_role?)
      bookmark_url = @person.consumer_role.bookmark_url.to_s.present? ? @person.consumer_role.bookmark_url.to_s + "?#{@key.to_s}=#{@val.to_s}" : nil
      redirect_to bookmark_url || family_account_path 
    end
  end


  def search
    @no_previous_button = true
    @no_save_button = true
    if params[:aqhp].present?
      session[:individual_assistance_path] = true
    else
      session.delete(:individual_assistance_path)
    end

    if params.permit(:build_consumer_role)[:build_consumer_role].present? && session[:person_id]
      person = Person.find(session[:person_id])

      @person_params = person.attributes.extract!("first_name", "middle_name", "last_name", "gender")
      @person_params[:ssn] = Person.decrypt_ssn(person.encrypted_ssn)
      @person_params[:dob] = person.dob.strftime("%Y-%m-%d")

      @person = Forms::ConsumerCandidate.new(@person_params)
    else
      @person = Forms::ConsumerCandidate.new
    end

    respond_to do |format|
      format.html
    end
  end

  def match
    @no_save_button = true
    @person_params = params.require(:person).merge({user_id: current_user.id})

    @consumer_candidate = Forms::ConsumerCandidate.new(@person_params)
    @person = @consumer_candidate
    respond_to do |format|
      if @consumer_candidate.valid?
        idp_search_result = nil
        if current_user.idp_verified?
          idp_search_result = :not_found
        else
          idp_search_result = IdpAccountManager.check_existing_account(@consumer_candidate)
        end
        case idp_search_result
        when :service_unavailable
          format.html { render 'shared/account_lookup_service_unavailable' }
        when :too_many_matches
          format.html { redirect_to SamlInformation.account_conflict_url }
        when :existing_account
          format.html { redirect_to SamlInformation.account_recovery_url }
        else
          unless params[:persisted] == "true"
            @employee_candidate = Forms::EmployeeCandidate.new(@person_params)

            if @employee_candidate.valid?
              found_census_employees = @employee_candidate.match_census_employees
              @employment_relationships = Factories::EmploymentRelationshipFactory.build(@employee_candidate, found_census_employees)
              if @employment_relationships.present?
                format.html { render 'insured/employee_roles/match' }
              end
            end
          end

          found_person = @consumer_candidate.match_person
          if found_person.present?
            format.html { render 'match' }
          else
            format.html { render 'no_match' }
          end
        end
      elsif @consumer_candidate.errors[:ssn_taken].present?
        text = "The SSN entered is associated with an existing user. "
        text += "Please #{view_context.link_to('Sign In', SamlInformation.iam_login_url)} with your user name and password "
        text += "or #{view_context.link_to('Click here', SamlInformation.account_recovery_url)} if you've forgotten your password."
        flash[:alert] = text
        format.html {redirect_to ssn_taken_insured_consumer_role_index_path}
      else
        format.html { render 'search' }
      end
    end
  end

  def build
    set_current_person(required: false)
    build_person_params
    render 'match'
  end

  def create
    begin
      @consumer_role = Factories::EnrollmentFactory.construct_consumer_role(params.permit!, actual_user)
      if @consumer_role.present?
        @person = @consumer_role.person
      else
      # not logging error because error was logged in construct_consumer_role
        render file: 'public/500.html', status: 500
        return
      end
    rescue Exception => e
      flash[:error] = set_error_message(e.message)
      redirect_to search_insured_consumer_role_index_path
      return
    end
    is_assisted = session["individual_assistance_path"]
    role_for_user = (is_assisted) ? "assisted_individual" : "individual"
    create_sso_account(current_user, @person, 15, role_for_user) do
      respond_to do |format|
        format.html {
          if is_assisted
            @person.primary_family.update_attribute(:e_case_id, "curam_landing_for#{@person.id}") if @person.primary_family
            redirect_to navigate_to_assistance_saml_index_path
          else
            redirect_to :action => "edit", :id => @consumer_role.id
          end
        }
      end
    end
  end

  def immigration_document_options
    if params[:target_type] == "Person"
      @target = Person.find(params[:target_id])
      vlp_docs = @target.consumer_role.vlp_documents
    elsif params[:target_type] == "Forms::FamilyMember"
      if params[:target_id].present?
        @target = Forms::FamilyMember.find(params[:target_id])
        vlp_docs = @target.family_member.person.consumer_role.vlp_documents
      else
        @target = Forms::FamilyMember.new
      end
    end
    @vlp_doc_target = params[:vlp_doc_target]
    vlp_doc_subject = params[:vlp_doc_subject]
    @country = vlp_docs.detect{|doc| doc.subject == vlp_doc_subject }.try(:country_of_citizenship) if vlp_docs
  end

  def edit
    #authorize @consumer_role, :edit?
    set_consumer_bookmark_url
    @consumer_role.build_nested_models_for_person
    @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@consumer_role)
  end

  def update
    #authorize @consumer_role, :update?
    save_and_exit =  params['exit_after_method'] == 'true'

    if update_vlp_documents(@consumer_role, 'person') && @consumer_role.update_by_person(params.require(:person).permit(*person_parameters_list))
      if save_and_exit
        respond_to do |format|
          format.html {redirect_to destroy_user_session_path}
        end
      else
        redirect_to ridp_agreement_insured_consumer_role_index_path
      end
    else
      if save_and_exit
        respond_to do |format|
          format.html {redirect_to destroy_user_session_path}
        end
      else
        @consumer_role.build_nested_models_for_person
        @vlp_doc_subject = get_vlp_doc_subject_by_consumer_role(@consumer_role)
        bubble_address_errors_by_person(@consumer_role.person)
        respond_to do |format|
          format.html { render "edit" }
        end
      end
    end
  end

  def ridp_agreement
    set_current_person
    if session[:original_application_type] == 'paper'
      redirect_to insured_family_members_path(:consumer_role_id => @person.consumer_role.id)
      return
    elsif @person.completed_identity_verification?
      redirect_to insured_family_members_path(:consumer_role_id => @person.consumer_role.id)
    else
      set_consumer_bookmark_url
    end
  end

  private
  def person_parameters_list
    [
      { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip] },
      { :phones_attributes => [:kind, :full_phone_number] },
      { :emails_attributes => [:kind, :address] },
      { :consumer_role_attributes => [:contact_method, :language_preference]},
      :first_name,
      :last_name,
      :middle_name,
      :name_pfx,
      :name_sfx,
      :dob,
      :ssn,
      :no_ssn,
      :gender,
      :language_code,
      :is_incarcerated,
      :is_disabled,
      :race,
      :is_consumer_role,
      {:ethnicity => []},
      :us_citizen,
      :naturalized_citizen,
      :eligible_immigration_status,
      :indian_tribe_member,
      :tribal_id,
      :no_dc_address,
      :no_dc_address_reason
    ]
  end

  def find_consumer_role
    @consumer_role = ConsumerRole.find(params.require(:id))
  end

  def check_consumer_role
    set_current_person(required: false)
    if @person.try(:has_active_consumer_role?)
      redirect_to @person.consumer_role.bookmark_url || family_account_path

    else
      current_user.last_portal_visited = search_insured_consumer_role_index_path
      current_user.save!
      # render 'privacy'
    end
  end

  def set_error_message(message)
    if message.include? "year too big to marshal"
      return "Date of birth cannot be more than 110 years ago"
    else
      return message
    end
  end

  def build_person_params
   @person_params = {:ssn =>  Person.decrypt_ssn(@person.encrypted_ssn)}

    %w(first_name middle_name last_name gender).each do |field|
      @person_params[field] = @person.attributes[field]
    end

    @person_params[:dob] = @person.dob.strftime("%Y-%m-%d")
    @person_params.merge!({user_id: current_user.id})
  end
end
