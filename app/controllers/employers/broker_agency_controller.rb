class Employers::BrokerAgencyController < ApplicationController
  include Acapi::Notifiers
  before_action :find_employer
  before_action :find_borker_agency, :except => [:index, :active_broker]
  before_action :updateable?, only: [:create, :terminate]

  def index
    @filter_criteria = params.permit(:q, :working_hours, :languages => [])

    if @filter_criteria.empty?
      @orgs = Organization.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop'])
      @page_alphabets = page_alphabets(@orgs, "legal_name")

      if params[:page].present?
        page_no = cur_page_no(@page_alphabets.first)
        @organizations = @orgs.where("legal_name" => /^#{page_no}/i)
      else
        @organizations = @orgs.to_a.first(10)
      end
      @broker_agency_profiles = @organizations.map(&:broker_agency_profile).uniq
    else
      results = Organization.broker_agencies_with_matching_agency_or_broker(@filter_criteria)
      if results.first.is_a?(Person)
        @filtered_broker_roles  = results.map(&:broker_role)
        @broker_agency_profiles = results.map{|broker| broker.broker_role.broker_agency_profile}.uniq
      else
        @broker_agency_profiles = results.map(&:broker_agency_profile).uniq
      end
    end
  end

  def show
  end

  def active_broker
    @broker_agency_account = @employer_profile.active_broker_agency_account
  end

  def create
    authorize EmployerProfile, :updateable?
    broker_agency_id = params.permit(:broker_agency_id)[:broker_agency_id]
    broker_role_id = params.permit(:broker_role_id)[:broker_role_id]

    if broker_agency_profile = BrokerAgencyProfile.find(broker_agency_id)
      @employer_profile.broker_role_id = broker_role_id
      @employer_profile.hire_broker_agency(broker_agency_profile)
      if broker_agency_profile.default_general_agency_profile.present?
        @employer_profile.hire_general_agency(broker_agency_profile.default_general_agency_profile, broker_agency_profile.primary_broker_role_id)
        send_general_agency_assign_msg(broker_agency_profile.default_general_agency_profile, @employer_profile, broker_agency_profile, 'Hire')
      end
      send_broker_assigned_msg(@employer_profile, broker_agency_profile)
      @employer_profile.save!(validate: false)
    end

    flash[:notice] = "Your broker has been notified of your selection and should contact you shortly. You can always call or email them directly. If this is not the broker you want to use, select 'Change Broker'."
    send_broker_successfully_associated_email broker_role_id
    redirect_to employers_employer_profile_path(@employer_profile, tab: 'brokers')
  rescue => e
    if @employer_profile.errors
      error_msg = @employer_profile.plan_years.select{|py| py.errors.present? }.map(&:errors).map(&:full_messages)
    end
    log("#4095 #{e.message}; employer_profile: #{@employer_profile.id}; #{error_msg}", {:severity => "error"})
  end


  def terminate
    authorize EmployerProfile, :updateable?
    if params["termination_date"].present?
      termination_date = DateTime.strptime(params["termination_date"], '%m/%d/%Y').try(:to_date)
      @employer_profile.fire_broker_agency(termination_date)
      @employer_profile.fire_general_agency!(termination_date)
      @fa = @employer_profile.save!(validate: false)
    end

    respond_to do |format|
      format.js {
        if params["termination_date"].present? && @fa
          flash[:notice] = "Broker terminated successfully."
          render text: true
        else
          render text: false
        end
      }
      format.all {
        flash[:notice] = "Broker terminated successfully."
        if params[:direct_terminate]
          redirect_to employers_employer_profile_path(@employer_profile, tab: "brokers")
        else
          redirect_to employers_employer_profile_path(@employer_profile)
        end
      }
    end
  end

  private

  def updateable?
    authorize @employer_profile, :updateable?
  end
  def send_broker_successfully_associated_email broker_role_id
    id =BSON::ObjectId.from_string(broker_role_id)
    @broker_person = Person.where(:'broker_role._id' => id).first
    body = "You have been selected as a broker by #{@employer_profile.try(:legal_name)}"

    from_provider = HbxProfile.current_hbx
    message_params = {
      sender_id: @employer_profile.try(:id),
      parent_message_id: @broker_person.id,
      from: @employer_profile.try(:legal_name),
      to: @broker_person.try(:full_name),
      body: body,
      subject: 'You have been select as the Broker'
    }

    create_secure_message(message_params, @broker_person, :inbox)
  end

  def send_general_agency_assign_msg(general_agency, employer_profile, broker_agency_profile, status)
    subject = "You are associated to #{broker_agency_profile.organization.legal_name}- #{general_agency.legal_name} (#{status})"
    body = "<br><p>Associated details<br>General Agency : #{general_agency.legal_name}<br>Employer : #{employer_profile.legal_name}<br>Status : #{status}</p>"
    secure_message(broker_agency_profile, general_agency, subject, body)
    secure_message(broker_agency_profile, employer_profile, subject, body)
  end

  def send_broker_assigned_msg(employer_profile, broker_agency_profile)
    broker_subject = "#{employer_profile.organization.legal_name} has selected you as the broker on DC Health Link"
    broker_body = "<br><p>Please contact your new client representative:<br> Employer Name: #{employer_profile.organization.legal_name}<br>Representative: #{employer_profile.staff_roles.first.try(:full_name)}<br>Email: #{employer_profile.staff_roles.first.try(:work_email_or_best)}<br>Phone: #{employer_profile.staff_roles.first.try(:work_phone).to_s}<br>Address: #{employer_profile.organization.primary_office_location.address.full_address}</p>"
    employer_subject = "You have selected #{broker_agency_profile.primary_broker_role.person.full_name} as your broker on DC Health Link."
    employer_body = "<br><p>Your new Broker: #{broker_agency_profile.primary_broker_role.person.full_name}<br> Phone: #{broker_agency_profile.phone.to_s}<br>Email: #{broker_agency_profile.primary_broker_role.person.emails.first.address}<br>Address: #{broker_agency_profile.organization.primary_office_location.address.full_address}</p>"
    secure_message(employer_profile, broker_agency_profile, broker_subject, broker_body)
    secure_message(broker_agency_profile, employer_profile, employer_subject, employer_body)
  end

  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end

  def find_borker_agency
    id = params[:id] || params[:broker_agency_id]
    @broker_agency_profile = BrokerAgencyProfile.find(id)
  end
end
