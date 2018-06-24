class GeneralAgencies::ProfilesController < ApplicationController
  skip_before_action :require_login, only: [:new_agency, :new_agency_staff, :create, :search_general_agency]
  skip_before_action :authenticate_me!, only: [:new_agency, :new_agency_staff, :create, :search_general_agency]
  #before_action :find_hbx_profile, only: [:index]
  before_action :find_general_agency_profile, only: [:show, :edit, :update, :employers, :families, :staffs, :agency_messages]
  before_action :find_general_agency_staff, only: [:edit_staff, :update_staff]
  before_action :check_general_agency_profile_permissions_index, only: [:index]
  before_action :check_general_agency_profile_permissions_new, only: [:new]

  layout 'single_column'

  def new
    flash[:notice] = "You don't have a General Agency Profile associated with your Account!! Please register your General Agency first."
  end

  def index
    @general_agency_profiles = GeneralAgencyProfile.all
  end

  def edit
    @organization = ::Forms::GeneralAgencyProfile.find(@general_agency_profile.id)
    @id = params[:id]
  end

  def update
    authorize HbxProfile, :modify_admin_tabs?
    sanitize_agency_profile_params
    params.permit!

    @organization = Organization.find(params[:organization][:id])
    @organization_dup = @organization.office_locations.as_json

    #clear office_locations, don't worry, we will recreate
    @organization.assign_attributes(:office_locations => [])
    @organization.save(validate: false)
    person = @general_agency_profile.primary_staff.person

    person.update_attributes(person_profile_params)

    @general_agency_profile.update_attributes(languages_spoken_params)


    if @organization.update_attributes(ga_profile_params)
      office_location = @organization.primary_office_location
      if office_location.present?
        update_ga_staff_phone(office_location, person)
      end
      flash[:notice] = "Successfully Update General Agency Profile"
      redirect_to general_agencies_profile_path(@general_agency_profile)
    else
      @organization.assign_attributes(:office_locations => @organization_dup)
      @organization.save(validate: false)
      flash[:error] = "Failed to Update General Agency Profile"
      redirect_to general_agencies_profile_path(@general_agency_profile)

    end
  end

  def new_agency
    @organization = ::Forms::GeneralAgencyProfile.new
  end

  def new_agency_staff
    @organization = ::Forms::GeneralAgencyProfile.new
  end

  def search_general_agency
    orgs = Organization.search_by_general_agency(params[:general_agency_search])

    @general_agency_profiles = orgs.present? ? orgs.map(&:general_agency_profile) : []
  end

  def create
    @organization = ::Forms::GeneralAgencyProfile.new(general_agency_profile_params)
    @organization.languages_spoken = params.require(:organization)[:languages_spoken].reject!(&:empty?) if params.require(:organization)[:languages_spoken].present?
    if @organization.save
      flash[:notice] = "Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed."
      redirect_to general_agency_registration_path
    else
      template = @organization.only_staff_role? ? "new_agency_staff" : "new_agency"
      render template
    end
  end

  def show
    set_flash_by_announcement
    @provider = current_user.person
    @staff_role = current_user.has_general_agency_staff_role?
    @id=params[:id]
  end

  def employers
    @datatable = Effective::Datatables::GeneralAgencyDataTable.new({id: params[:id]})
  end

  def families
    @datatable = Effective::Datatables::GeneralAgencyFamilyDataTable.new({id: params[:id]})
  end

  # def families
  #   page = params.permit([:page])[:page]
  #   @q = params.permit(:q)[:q]

  #   total_families = @general_agency_profile.families
  #   @total = total_families.count
  #   @page_alphabets = total_families.map{|f| f.primary_applicant.person.last_name[0]}.map(&:capitalize).uniq
  #   if page.present?
  #     @families = total_families.select{|v| v.primary_applicant.person.last_name =~ /^#{page}/i }
  #   elsif @q.present?
  #     query= Regexp.escape(@q)
  #     query_args= query.split("\\ ")
  #     reg_ex = query_args.join('(.*)?')
  #     @families = total_families.select {|v| v.primary_applicant.person.full_name =~ /#{reg_ex}/i}
  #   else
  #     @families = total_families[0..20]
  #   end
  # end

  def staffs
    @staffs = @general_agency_profile.general_agency_staff_roles
  end

  def edit_staff
    respond_to do |format|
      format.js
      format.html
    end
  end

  def update_staff
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

    redirect_to general_agencies_profile_path(@staff.general_agency_profile)
  end

  def messages
    @sent_box = true
    @provider = current_user.person
  end

  def agency_messages
    @sent_box = true
  end

  def inbox
    @sent_box = true
    id = params["id"]||params['profile_id']
    @general_agency_provider = GeneralAgencyProfile.find(id)
    @folder = (params[:folder] || 'Inbox').capitalize
    if current_user.person._id.to_s == id
      @provider = current_user.person
    else
      @provider = @general_agency_provider
    end
  end

  def redirect_to_show(general_agency_profile_id)
    redirect_to general_agencies_profile_path(id: general_agency_profile_id)
  end

  def redirect_to_new
    redirect_to new_general_agencies_profile_path
  end

  private
  def find_general_agency_profile
    @general_agency_profile = GeneralAgencyProfile.find(params[:id])
  end

  def find_hbx_profile
    @profile = current_user.person.hbx_staff_role.hbx_profile
  end

  def find_general_agency_staff
    @staff = GeneralAgencyStaffRole.find(params[:id])
  end

  def check_general_agency_profile_permissions_index
    policy = ::AccessPolicies::GeneralAgencyProfile.new(current_user)
    policy.authorize_index(self)
  end

  def check_general_agency_profile_permissions_new
    policy = ::AccessPolicies::GeneralAgencyProfile.new(current_user)
    policy.authorize_new(self)
  end

  def general_agency_profile_params
    params.require(:organization).permit(
      :first_name, :last_name, :dob, :email, :npn, :legal_name, :dba,
      :fein, :entity_kind, :home_page, :market_kind, :languages_spoken,
      :working_hours, :accept_new_clients, :general_agency_profile_id, :applicant_type,
      :office_locations_attributes => [
        :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
        :phone_attributes => [:kind, :area_code, :number, :extension]
      ]
    )
  end

  def sanitize_agency_profile_params
    params[:organization][:office_locations_attributes].each do |key, location|
      params[:organization][:office_locations_attributes].delete(key) unless location['address_attributes']
      location.delete('phone_attributes') if (location['phone_attributes'].present? && location['phone_attributes']['number'].blank?)
    end
  end

  def person_profile_params
    params.require(:organization).permit(:first_name, :last_name, :dob)
  end

  def languages_spoken_params
    params.require(:organization).permit(
      :languages_spoken => []
    )
  end

  def ga_profile_params
    params.require(:organization).permit(
      :legal_name,
      :dba,
      :home_page,
      :office_locations_attributes => [
        :address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip],
        :phone_attributes => [:kind, :area_code, :number, :extension],
        :email_attributes => [:kind, :address]
      ]
    )
  end

  def update_ga_staff_phone(office_location, person)
    phone = office_location.phone
    broker_main_phone = person.phones.where(kind: "phone main").first
    if broker_main_phone.present?
      broker_main_phone.update_attributes!(
        kind: phone.kind,
        country_code: phone.country_code,
        area_code: phone.area_code,
        number: phone.number,
        extension: phone.extension,
        full_phone_number: phone.full_phone_number
      )
    end
    person.save!
  end

  def send_secure_message_to_general_agency(staff_role)
    hbx_admin = HbxProfile.all.first
    general_agency = staff_role.general_agency_profile

    subject = "Received new general agency - #{staff_role.person.full_name}"
    body = "<br><p>Following are staff details<br>Staff Name : #{staff_role.person.full_name}<br>Staff NPN  : #{staff_role.npn}</p>"
    secure_message(hbx_admin, general_agency, subject, body)
  end
end
