class Exchanges::AgentsController < ApplicationController
  before_action :check_agent_role
  def home
     @title = current_user.agent_title
     person_id = session[:person_id]
     @person=nil
     @person = Person.find(person_id) if person_id.present?
     if @person && !@person.csr_role && !@person.assister_role
       root = 'http://' + request.env["HTTP_HOST"]+'/exchanges/agents/resume_enrollment?person_id=' + person_id
       hbx_profile = HbxProfile.find_by_state_abbreviation('DC')
       message_params = {
         sender_id: hbx_profile.id,
         parent_message_id: hbx_profile.id,
         from: 'Plan Shopping Web Portal',
         to: "Agent Mailbox",
         subject: "Account link for  #{@person.full_name}. ",
         body: "<a href='" + root+"'>Link to access #{@person.full_name}</a>  <br>",
       }
       create_secure_message message_params, current_user.person, :inbox
     end
     session[:person_id] = nil
     session[:original_application_type] = nil
     render 'home'
  end

  def begin_employee_enrollment
    session[:person_id] = nil
    session[:original_application_type] = params['original_application_type']
    redirect_to search_insured_employee_index_path
  end

  def begin_consumer_enrollment
    session[:person_id] = nil
    session[:original_application_type] = params['original_application_type']
    redirect_to search_insured_consumer_role_index_path
  end

  def resume_enrollment
    session[:person_id] = params[:person_id]
    session[:original_application_type] = params['original_application_type']
    person = Person.find(params[:person_id])
    consumer_role = person.consumer_role
    employee_role = person.employee_roles.last
    person.set_consumer_role_url
    if consumer_role && consumer_role.bookmark_url
      redirect_to bookmark_url_path(consumer_role.bookmark_url)
    elsif employee_role && employee_role.bookmark_url
      redirect_to bookmark_url_path(employee_role.bookmark_url)
    else
      redirect_to family_account_path
    end
  end

  def inbox
    @inbox_provider = current_user.person
    @profile=@inbox_provider
    @folder = params[:folder] || 'inbox'
    @sent_box = false
  end

  def show
  end

  def check_agent_role
    unless current_user.has_agent_role? || current_user.has_hbx_staff_role? || current_user.has_broker_role? || current_user.has_general_agency_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an Agent:  CSR, CAC, IPA or a Broker" }
    end
    current_user.last_portal_visited = home_exchanges_agents_path
    current_user.save!
  end


  private

  def bookmark_url_path(bookmark_url)
    uri = URI.parse(bookmark_url)
    bookmark_path = uri.path
    bookmark_path += "?#{uri.query}" unless uri.query.blank?
    return bookmark_path
  end
end




