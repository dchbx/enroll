class BrokerAgencies::ProfilesController < ApplicationController
  include Acapi::Notifiers
  include Config::AcaConcern
  include DataTablesAdapter

  before_action :check_broker_agency_staff_role, only: [:new, :create]
  before_action :check_admin_staff_role, only: [:index]
  before_action :find_hbx_profile, only: [:index]
  before_action :find_broker_agency_profile, only: [:show, :edit, :update, :employers, :assign, :update_assign, :employer_datatable, :manage_employers, :general_agency_index, :clear_assign_for_employer, :set_default_ga, :assign_history]
  before_action :set_current_person, only: [:staff_index]
  before_action :check_general_agency_profile_permissions_assign, only: [:assign, :update_assign, :clear_assign_for_employer, :assign_history]
  before_action :check_general_agency_profile_permissions_set_default, only: [:set_default_ga]
  before_action :redirect_unless_general_agency_is_enabled?, only: [:assign, :update_assign]
  before_action :check_and_download_commission_statement, only: [:download_commission_statement, :show_commission_statement]

  layout 'single_column'

  EMPLOYER_DT_COLUMN_TO_FIELD_MAP = {
    "2"     => "legal_name",
    "4"     => "employer_profile.aasm_state",
    "5"     => "employer_profile.plan_years.start_on"
  }

  def index
    @broker_agency_profiles = BrokerAgencyProfile.all
  end

  def new
    @organization = ::Forms::BrokerAgencyProfile.new
  end

  def create
    params.permit!
    @organization = ::Forms::BrokerAgencyProfile.new(params[:organization])

    if @organization.save(current_user)
      flash[:notice] = "Successfully created Broker Agency Profile"
      redirect_to broker_agencies_profile_path(@organization.broker_agency_profile)
    else
      flash[:error] = "Failed to create Broker Agency Profile"
      render "new"
    end
  end

  def show
    set_flash_by_announcement
    session[:person_id] = nil
     @provider = @broker_agency_profile.primary_broker_role.person
     @staff_role = current_user.has_broker_agency_staff_role?
     @id=params[:id]
  end

  def edit
    @organization = Forms::BrokerAgencyProfile.find(@broker_agency_profile.id)
    @id = params[:id]
  end

  def update
    authorize HbxProfile, :modify_admin_tabs?
    sanitize_broker_profile_params
    params.permit!

    # lookup by the origanization and not BrokerAgencyProfile
    broker_agency_profile = ::Forms::BrokerAgencyProfile.new(params.require(:organization))

    @organization = Organization.find(params[:organization][:id])
    @organization_dup = @organization.office_locations.as_json

    #clear office_locations, don't worry, we will recreate
    @organization.assign_attributes(:office_locations => [])
    @organization.save(validate: false)
    person = @broker_agency_profile.primary_broker_role.person

    person.update_attributes(person_profile_params)
    @broker_agency_profile.update_attributes(languages_spoken_params.merge(ach_account_number: broker_agency_profile.ach_record.account_number, ach_routing_number: broker_agency_profile.ach_record.routing_number))


    if @organization.update_attributes(broker_profile_params)
      office_location = @organization.primary_office_location
      if office_location.present?
        update_broker_phone(office_location, person)
      end

      flash[:notice] = "Successfully Update Broker Agency Profile"
      redirect_to broker_agencies_profile_path(@broker_agency_profile)
    else

      @organization.assign_attributes(:office_locations => @organization_dup)
      @organization.save(validate: false)

      flash[:error] = "Failed to Update Broker Agency Profile"
      #render "edit"
      redirect_to broker_agencies_profile_path(@broker_agency_profile)

    end
  end

  def staff_index
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

  def family_datatable
    id = params[:id]

    is_search = false

    dt_query = extract_datatable_parameters

    if current_user.has_broker_role?
      @broker_agency_profile = BrokerAgencyProfile.find(current_user.person.broker_role.broker_agency_profile_id)
    elsif current_user.has_hbx_staff_role?
      @broker_agency_profile = BrokerAgencyProfile.find(BSON::ObjectId.from_string(id))
    else
      redirect_to new_broker_agencies_profile_path
      return
    end

    query = Queries::BrokerFamiliesQuery.new(dt_query.search_string, @broker_agency_profile.id)

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
    @q = params.permit(:q)[:q]
    id = params.permit(:id)[:id]
    page = params.permit([:page])[:page]
    if current_user.has_broker_role?
      @broker_agency_profile = BrokerAgencyProfile.find(current_user.person.broker_role.broker_agency_profile_id)
    elsif current_user.has_hbx_staff_role?
      @broker_agency_profile = BrokerAgencyProfile.find(BSON::ObjectId.from_string(id))
    else
      redirect_to new_broker_agencies_profile_path
      return
    end
    #
    # total_families = @broker_agency_profile.families
    # @total = total_families.count
    # @page_alphabets = total_families.map{|f| f.primary_applicant.person.last_name[0]}.map(&:capitalize).uniq
    # if page.present?
    #   @families = total_families.select{|v| v.primary_applicant.person.last_name =~ /^#{page}/i }
    # elsif @q.present?
    #   query= Regexp.escape(@q)
    #   query_args= query.split("\\ ")
    #   reg_ex = query_args.join('(.*)?')
    #   @families = total_families.select{|v| v.primary_applicant.person.full_name =~ /#{reg_ex}/i }
    # else
    #   @families = total_families[0..20]
    # end
    #
    # @family_count = @families.count
    respond_to do |format|
      format.js {}
    end
  end

  def commission_statements
    permitted = params.permit(:id)
    @id = permitted[:id]
    if current_user.has_broker_role?
      @broker_agency_profile = BrokerAgencyProfile.find(current_user.person.broker_role.broker_agency_profile_id)
    elsif current_user.has_hbx_staff_role?
      @broker_agency_profile = BrokerAgencyProfile.find(BSON::ObjectId.from_string(@id))
    else
      redirect_to new_broker_agencies_profile_path
      return
    end
    documents = @broker_agency_profile.organization.documents
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
    if current_user.has_broker_agency_staff_role? || current_user.has_hbx_staff_role?
      @orgs = Organization.by_broker_agency_profile(@broker_agency_profile._id)
    else
      broker_role_id = current_user.person.broker_role.id
      @orgs = Organization.by_broker_role(broker_role_id)
    end
    @memo = {}
    @broker_role = current_user.person.broker_role || nil
    @general_agency_profiles = GeneralAgencyProfile.all_by_broker_role(@broker_role, approved_only: true)
  end

  def general_agency_index
    @broker_role = current_user.person.broker_role || nil
    @general_agency_profiles = GeneralAgencyProfile.all_by_broker_role(@broker_role, approved_only: true)
  end

  def set_default_ga
    authorize HbxProfile, :modify_admin_tabs?
    @general_agency_profile = GeneralAgencyProfile.find(params[:general_agency_profile_id]) rescue nil
    if @broker_agency_profile.present?
      old_default_ga_id = @broker_agency_profile.default_general_agency_profile.id.to_s rescue nil
      if params[:type] == 'clear'
        @broker_agency_profile.default_general_agency_profile = nil
      elsif @general_agency_profile.present?
        @broker_agency_profile.default_general_agency_profile = @general_agency_profile
        @broker_agency_profile.employer_clients.each do |employer_profile|
          @general_agency_profile.general_agency_hired_notice(employer_profile) # GA notice when broker selects a default GA 
        end
      end
      @broker_agency_profile.save
      notify("acapi.info.events.broker.default_ga_changed", {:broker_id => @broker_agency_profile.primary_broker_role.hbx_id, :pre_default_ga_id => old_default_ga_id})
      @notice = "Changing default general agencies may take a few minutes to update all employers."

      @broker_role = current_user.person.broker_role || nil
      @general_agency_profiles = GeneralAgencyProfile.all_by_broker_role(@broker_role, approved_only: true)
    end

    respond_to do |format|
      format.js
    end
  end

  def employer_datatable
    order_by = EMPLOYER_DT_COLUMN_TO_FIELD_MAP[params[:order]["0"][:column]].try(:to_sym)

    cursor        = params[:start]  || 0
    page_size     = params[:length] || 10

    is_search = false

    dt_query = extract_datatable_parameters

    if current_user.has_broker_agency_staff_role? || current_user.has_hbx_staff_role?
      @orgs = Organization.unscoped.by_broker_agency_profile(@broker_agency_profile._id)
    else
      broker_role_id = current_user.person.broker_role.id
      @orgs = Organization.unscoped.by_broker_role(broker_role_id)
    end

    if order_by.present?
      # If searching on column 5 (PY start_on), also sort by aasm_state
      @orgs = params[:order]["0"][:column] == 5 ? @orgs.order_by(:'employer_profile.plan_years.aasm_state'.asc, order_by.send(params[:order]["0"][:dir])) : @orgs.order_by(order_by.send(params[:order]["0"][:dir]))
    end

    total_records = @orgs.count

    if params[:search][:value].present?
      @orgs = @orgs.where(legal_name: /.*#{dt_query.search_string}.*/i)
      is_search = true
    end

    employer_profiles = @orgs.skip(dt_query.skip).limit(dt_query.take).map { |o| o.employer_profile } unless @orgs.blank?
    employer_ids = employer_profiles.present? ? employer_profiles.map(&:id) : []
    @census_totals = Hash.new(0)
    census_member_counts = CensusMember.collection.aggregate([
      { "$match" => {aasm_state: {"$in"=> CensusEmployee::EMPLOYMENT_ACTIVE_STATES}, employer_profile_id: {"$in" => employer_ids}}},
      { "$group" => {"_id" => "$employer_profile_id", "count" => {"$sum" => 1}}}
    ])
    census_member_counts.each do |cmc|
      @census_totals[cmc["_id"]] = cmc["count"]
    end
    @memo = {}

    @records_filtered = is_search ? @orgs.count : total_records
    @total_records = total_records
    broker_role = current_user.person.broker_role || nil
    if general_agency_is_enabled?
      @general_agency_profiles = GeneralAgencyProfile.all_by_broker_role(broker_role, approved_only: true)
    end
    @draw = dt_query.draw
    @employer_profiles = employer_profiles.present? ? employer_profiles : []
    render
  end

  def assign

    page_string = params.permit(:employers_page)[:employers_page]
    page_no = page_string.blank? ? nil : page_string.to_i
    if current_user.has_broker_agency_staff_role? || current_user.has_hbx_staff_role?
      @orgs = Organization.by_broker_agency_profile(@broker_agency_profile._id)
    else
      broker_role_id = current_user.person.broker_role.id
      @orgs = Organization.by_broker_role(broker_role_id)
    end
    @broker_role = current_user.person.broker_role || nil
    @general_agency_profiles = GeneralAgencyProfile.all_by_broker_role(@broker_role, approved_only: true)

    @employers = @orgs.map(&:employer_profile)
    @employers = Kaminari.paginate_array(@employers).page page_no
  end

  def update_assign
    params[:general_agency_id] = params[:employers_general_agency_id] if params[:employers_general_agency_id]
    authorize HbxProfile, :modify_admin_tabs?
    if params[:general_agency_id].present? || params[:employer_ids].present? && params[:bulk_actions_resources].present?
      general_agency_profile = GeneralAgencyProfile.find(params[:general_agency_id])
      case params[:type]
      when 'fire'
        params[:employer_ids].each do |employer_id|
          employer_profile = EmployerProfile.find(employer_id) rescue next

          employer_profile.fire_general_agency!
          send_general_agency_assign_msg(general_agency_profile, employer_profile, 'Terminate')
        end
        notice = "Fire these employers successful."
      else
        employer_ids = if params.key? :bulk_actions_resources
        params[:bulk_actions_resources].map do |pdo_id|
          SponsoredBenefits::Organizations::PlanDesignOrganization.find(pdo_id).employer_profile.id
        end
        else
          params[:employer_ids]
        end
        employer_ids.each do |employer_id|
          employer_profile = EmployerProfile.find(employer_id) rescue nil
          if employer_profile.present? #FIXME : Please move me to model
            broker_role_id = current_user.person.broker_role.id rescue nil
            broker_role_id ||= @broker_agency_profile.primary_broker_role_id
            employer_profile.hire_general_agency(general_agency_profile, broker_role_id)
            employer_profile.save
            send_general_agency_assign_msg(general_agency_profile, employer_profile, 'Hire')
            general_agency_profile.general_agency_hired_notice(employer_profile) #GA notice when broker Assign a GA to employers
          end
        end
        flash.now[:notice] ="Assign successful."
        if params["from_assign"] == "true"
          assign # calling this method as the latest copy of objects are needed.
          render "assign" and return
        else
          employers # calling this method as the latest copy of objects are needed.
          render "update_assign" and return
        end
      end
    elsif params["commit"].try(:downcase) == "clear assignment"
      employer_ids = if params.key? :bulk_actions_resources
      params[:bulk_actions_resources].map do |pdo_id|
        SponsoredBenefits::Organizations::PlanDesignOrganization.find(pdo_id).employer_profile.id
      end
      else
        params[:employer_ids]
      end
      employer_ids.each do |employer_id|
        employer_profile = EmployerProfile.find(employer_id) rescue next
        if employer_profile.general_agency_profile.present?
          send_general_agency_assign_msg(employer_profile.general_agency_profile, employer_profile, 'Terminate')
          employer_profile.fire_general_agency!
        end
      end
      notice = "Unassign successful."
    end
    redirect_to broker_agencies_profile_path(@broker_agency_profile), flash: {notice: notice}
  end

  def clear_assign_for_employer
    @broker_role = current_user.person.broker_role || nil
    @general_agency_profiles = GeneralAgencyProfile.all_by_broker_role(@broker_role, approved_only: true)
    
    authorize HbxProfile, :modify_admin_tabs?
    @employer_profile = EmployerProfile.find(params[:employer_id]) rescue nil
    if @employer_profile.present?
      send_general_agency_assign_msg(@employer_profile.general_agency_profile, @employer_profile, 'Terminate')
      @employer_profile.fire_general_agency!
    end
  end

  def assign_history
    page_string = params.permit(:gas_page)[:gas_page]
    page_no = page_string.blank? ? nil : page_string.to_i

    if current_user.has_hbx_staff_role?
      @general_agency_account_history = Kaminari.paginate_array(GeneralAgencyAccount.all).page page_no
    elsif current_user.has_broker_role? && current_user.person.broker_role.present?
      broker_role_id = @broker_agency_profile.present? ? @broker_agency_profile.primary_broker_role_id : current_user.person.broker_role.id
      @general_agency_account_history = Kaminari.paginate_array(GeneralAgencyAccount.find_by_broker_role_id(broker_role_id)).page page_no
    else
      @general_agency_account_history = Kaminari.paginate_array(Array.new)
    end
  end

  def manage_employers
    @general_agency_profile = GeneralAgencyProfile.find(params[:general_agency_profile_id])
    @employers = @general_agency_profile.employer_clients
  end

  def messages
    @sent_box = true
    @provider = Person.find(params["id"])
    @broker_agency_profile = BrokerAgencyProfile.find(params[:profile_id])
  end

  def agency_messages
    @sent_box = true
    @broker_agency_profile = current_user.person.broker_agency_staff_roles.first.broker_agency_profile
  end

  def inbox
    @sent_box = true
    id = params["id"]||params['profile_id']
    @broker_agency_provider = BrokerAgencyProfile.find(id)
    @folder = (params[:folder] || 'Inbox').capitalize
    if current_user.person._id.to_s == id
      @provider = current_user.person
    else
      @provider = @broker_agency_provider
    end
  end

  def redirect_to_show(broker_agency_profile_id)
    redirect_to broker_agencies_profile_path(id: broker_agency_profile_id)
  end

  private

  def broker_profile_params
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

  def languages_spoken_params
    params.require(:organization).permit(
      :accept_new_clients,
      :working_hours,
      :languages_spoken => []
    )
  end

  def person_profile_params
    params.require(:organization).permit(:first_name, :last_name, :dob)
  end

  def sanitize_broker_profile_params
    params[:organization][:office_locations_attributes].each do |key, location|
      params[:organization][:office_locations_attributes].delete(key) unless location['address_attributes']
      location.delete('phone_attributes') if (location['phone_attributes'].present? && location['phone_attributes']['number'].blank?)
    end
  end

  def check_and_download_commission_statement
      @broker_agency_profile = BrokerAgencyProfile.find(params[:id])
      authorize @broker_agency_profile, :access_to_broker_agency_profile?
      @commission_statement = @broker_agency_profile.organization.documents.find(params[:statement_id])
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
    #sort_order == 'ASC' ? @statements.sort_by!(&:date) : @statements.sort_by!(&:date).reverse!
    @statements.sort_by!(&:date).reverse!
  end

  def find_hbx_profile
    @profile = current_user.person.hbx_staff_role.hbx_profile
  end

  def find_broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(params[:id])
    authorize @broker_agency_profile, :access_to_broker_agency_profile?
  end

  def check_admin_staff_role
    if current_user.has_hbx_staff_role? || current_user.has_csr_role?
    elsif current_user.has_broker_agency_staff_role?
      redirect_to broker_agencies_profile_path(:id => current_user.person.broker_agency_staff_roles.first.broker_agency_profile_id)
    else
      redirect_to new_broker_agencies_profile_path
    end
  end

  def check_broker_agency_staff_role
    if current_user.has_broker_agency_staff_role?
      redirect_to broker_agencies_profile_path(:id => current_user.person.broker_agency_staff_roles.first.broker_agency_profile_id)
    elsif current_user.has_broker_role?
      redirect_to broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id.to_s)
    else
      flash[:notice] = "You don't have a Broker Agency Profile associated with your Account!! Please register your Broker Agency first."
    end
  end

  def send_general_agency_assign_msg(general_agency, employer_profile, status)
    subject = "You are associated to #{employer_profile.legal_name}- #{general_agency.legal_name} (#{status})"
    body = "<br><p>Associated details<br>General Agency : #{general_agency.legal_name}<br>Employer : #{employer_profile.legal_name}<br>Status : #{status}</p>"
    secure_message(@broker_agency_profile, general_agency, subject, body)
    secure_message(@broker_agency_profile, employer_profile, subject, body)
  end

  def eligible_brokers
    Person.where('broker_role.broker_agency_profile_id': {:$exists => true}).where(:'broker_role.aasm_state'=> 'active').any_in(:'broker_role.market_kind'=>[person_market_kind, "both"])
  end

  def update_ga_for_employers(broker_agency_profile, old_default_ga=nil)
    return if broker_agency_profile.blank?

    orgs = Organization.by_broker_agency_profile(broker_agency_profile.id)
    employer_profiles = orgs.map {|o| o.employer_profile}
    if broker_agency_profile.default_general_agency_profile.blank?
      employer_profiles.each do |employer_profile|
        general_agency = employer_profile.active_general_agency_account.general_agency_profile rescue nil
        if general_agency && general_agency == old_default_ga
          send_general_agency_assign_msg(general_agency, employer_profile, 'Terminate')
          employer_profile.fire_general_agency!
        end
      end
    else
      employer_profiles.each do |employer_profile|
        employer_profile.hire_general_agency(broker_agency_profile.default_general_agency_profile, broker_agency_profile.primary_broker_role_id)
        employer_profile.save
        send_general_agency_assign_msg(broker_agency_profile.default_general_agency_profile, employer_profile, 'Hire')
      end
    end
  end

  def person_market_kind
    if @person.has_active_consumer_role?
      "individual"
    elsif @person.has_active_employee_role?
      "shop"
    end
  end

  def check_general_agency_profile_permissions_assign
    @broker_agency_profile = BrokerAgencyProfile.find(params[:id])
    policy = ::AccessPolicies::GeneralAgencyProfile.new(current_user)
    policy.authorize_assign(self, @broker_agency_profile)
  end

  def check_general_agency_profile_permissions_set_default
    @broker_agency_profile = BrokerAgencyProfile.find(params[:id])
    policy = ::AccessPolicies::GeneralAgencyProfile.new(current_user)
    policy.authorize_set_default_ga(self, @broker_agency_profile)
  end

  def update_broker_phone(office_location, person)
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
end
