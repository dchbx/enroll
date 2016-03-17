class Exchanges::HbxProfilesController < ApplicationController

  before_action :check_hbx_staff_role, except: [:request_help, :show, :assister_index, :family_index]
  before_action :set_hbx_profile, only: [:edit, :update, :destroy]
  before_action :find_hbx_profile, only: [:employer_index, :broker_agency_index, :inbox, :configuration, :show, :binder_index]
  #before_action :authorize_for, except: [:edit, :update, :destroy, :request_help, :staff_index, :assister_index]
  #before_action :authorize_for_instance, only: [:edit, :update, :destroy]
  before_action :check_csr_or_hbx_staff, only: [:family_index]
  # GET /exchanges/hbx_profiles
  # GET /exchanges/hbx_profiles.json
  def index
    @organizations = Organization.exists(hbx_profile: true)
    @hbx_profiles = @organizations.map {|o| o.hbx_profile}
  end

  def binder_index
    # @employer_profile = EmployerProfile.all
    @data = {
   "data": [
      [
         "1",
         "Tiger Nixon",
         "System Architect",
         "Edinburgh",
         "5421",
         "2011/04/25",
         "$320,800"
      ],
      [
         "2",
         "Garrett Winters",
         "Accountant",
         "Tokyo",
         "8422",
         "2011/07/25",
         "$170,750"
      ],
      [
         "3",
         "Ashton Cox",
         "Junior Technical Author",
         "San Francisco",
         "1562",
         "2009/01/12",
         "$86,000"
      ],
      [
         "4",
         "Cedric Kelly",
         "Senior Javascript Developer",
         "Edinburgh",
         "6224",
         "2012/03/29",
         "$433,060"
      ],
      [
         "5",
         "Airi Satou",
         "Accountant",
         "Tokyo",
         "5407",
         "2008/11/28",
         "$162,700"
      ],
      [
         "6",
         "Brielle Williamson",
         "Integration Specialist",
         "New York",
         "4804",
         "2012/12/02",
         "$372,000"
      ],
      [
         "7",
         "Herrod Chandler",
         "Sales Assistant",
         "San Francisco",
         "9608",
         "2012/08/06",
         "$137,500"
      ],
      [
         "8",
         "Rhona Davidson",
         "Integration Specialist",
         "Tokyo",
         "6200",
         "2010/10/14",
         "$327,900"
      ],
      [
         "9",
         "Colleen Hurst",
         "Javascript Developer",
         "San Francisco",
         "2360",
         "2009/09/15",
         "$205,500"
      ],
      [
         "10",
         "Sonya Frost",
         "Software Engineer",
         "Edinburgh",
         "1667",
         "2008/12/13",
         "$103,600"
      ],
      [
         "11",
         "Jena Gaines",
         "Office Manager",
         "London",
         "3814",
         "2008/12/19",
         "$90,560"
      ],
      [
         "12",
         "Quinn Flynn",
         "Support Lead",
         "Edinburgh",
         "9497",
         "2013/03/03",
         "$342,000"
      ],
      [
         "13",
         "Charde Marshall",
         "Regional Director",
         "San Francisco",
         "6741",
         "2008/10/16",
         "$470,600"
      ],
      [
         "14",
         "Haley Kennedy",
         "Senior Marketing Designer",
         "London",
         "3597",
         "2012/12/18",
         "$313,500"
      ],
      [
         "15",
         "Tatyana Fitzpatrick",
         "Regional Director",
         "London",
         "1965",
         "2010/03/17",
         "$385,750"
      ],
      [
         "16",
         "Michael Silva",
         "Marketing Designer",
         "London",
         "1581",
         "2012/11/27",
         "$198,500"
      ],
      [
         "17",
         "Paul Byrd",
         "Chief Financial Officer (CFO)",
         "New York",
         "3059",
         "2010/06/09",
         "$725,000"
      ],
      [
         "18",
         "Gloria Little",
         "Systems Administrator",
         "New York",
         "1721",
         "2009/04/10",
         "$237,500"
      ],
      [
         "19",
         "Bradley Greer",
         "Software Engineer",
         "London",
         "2558",
         "2012/10/13",
         "$132,000"
      ],
      [
         "20",
         "Dai Rios",
         "Personnel Lead",
         "Edinburgh",
         "2290",
         "2012/09/26",
         "$217,500"
      ],
      [
         "21",
         "Jenette Caldwell",
         "Development Lead",
         "New York",
         "1937",
         "2011/09/03",
         "$345,000"
      ],
      [
         "22",
         "Yuri Berry",
         "Chief Marketing Officer (CMO)",
         "New York",
         "6154",
         "2009/06/25",
         "$675,000"
      ],
      [
         "23",
         "Caesar Vance",
         "Pre-Sales Support",
         "New York",
         "8330",
         "2011/12/12",
         "$106,450"
      ],
      [
         "24",
         "Doris Wilder",
         "Sales Assistant",
         "Sidney",
         "3023",
         "2010/09/20",
         "$85,600"
      ],
      [
         "25",
         "Angelica Ramos",
         "Chief Executive Officer (CEO)",
         "London",
         "5797",
         "2009/10/09",
         "$1,200,000"
      ],
      [
         "26",
         "Gavin Joyce",
         "Developer",
         "Edinburgh",
         "8822",
         "2010/12/22",
         "$92,575"
      ],
      [
         "27",
         "Jennifer Chang",
         "Regional Director",
         "Singapore",
         "9239",
         "2010/11/14",
         "$357,650"
      ],
      [
         "28",
         "Brenden Wagner",
         "Software Engineer",
         "San Francisco",
         "1314",
         "2011/06/07",
         "$206,850"
      ],
      [
         "29",
         "Fiona Green",
         "Chief Operating Officer (COO)",
         "San Francisco",
         "2947",
         "2010/03/11",
         "$850,000"
      ],
      [
         "30",
         "Shou Itou",
         "Regional Marketing",
         "Tokyo",
         "8899",
         "2011/08/14",
         "$163,000"
      ],
      [
         "31",
         "Michelle House",
         "Integration Specialist",
         "Sidney",
         "2769",
         "2011/06/02",
         "$95,400"
      ],
      [
         "32",
         "Suki Burks",
         "Developer",
         "London",
         "6832",
         "2009/10/22",
         "$114,500"
      ],
      [
         "33",
         "Prescott Bartlett",
         "Technical Author",
         "London",
         "3606",
         "2011/05/07",
         "$145,000"
      ],
      [
         "34",
         "Gavin Cortez",
         "Team Leader",
         "San Francisco",
         "2860",
         "2008/10/26",
         "$235,500"
      ],
      [
         "35",
         "Martena Mccray",
         "Post-Sales support",
         "Edinburgh",
         "8240",
         "2011/03/09",
         "$324,050"
      ],
      [
         "36",
         "Unity Butler",
         "Marketing Designer",
         "San Francisco",
         "5384",
         "2009/12/09",
         "$85,675"
      ],
      [
         "37",
         "Howard Hatfield",
         "Office Manager",
         "San Francisco",
         "7031",
         "2008/12/16",
         "$164,500"
      ],
      [
         "38",
         "Hope Fuentes",
         "Secretary",
         "San Francisco",
         "6318",
         "2010/02/12",
         "$109,850"
      ],
      [
         "39",
         "Vivian Harrell",
         "Financial Controller",
         "San Francisco",
         "9422",
         "2009/02/14",
         "$452,500"
      ],
      [
         "40",
         "Timothy Mooney",
         "Office Manager",
         "London",
         "7580",
         "2008/12/11",
         "$136,200"
      ],
      [
         "41",
         "Jackson Bradshaw",
         "Director",
         "New York",
         "1042",
         "2008/09/26",
         "$645,750"
      ],
      [
         "42",
         "Olivia Liang",
         "Support Engineer",
         "Singapore",
         "2120",
         "2011/02/03",
         "$234,500"
      ],
      [
         "43",
         "Bruno Nash",
         "Software Engineer",
         "London",
         "6222",
         "2011/05/03",
         "$163,500"
      ],
      [
         "44",
         "Sakura Yamamoto",
         "Support Engineer",
         "Tokyo",
         "9383",
         "2009/08/19",
         "$139,575"
      ],
      [
         "45",
         "Thor Walton",
         "Developer",
         "New York",
         "8327",
         "2013/08/11",
         "$98,540"
      ],
      [
         "46",
         "Finn Camacho",
         "Support Engineer",
         "San Francisco",
         "2927",
         "2009/07/07",
         "$87,500"
      ],
      [
         "47",
         "Serge Baldwin",
         "Data Coordinator",
         "Singapore",
         "8352",
         "2012/04/09",
         "$138,575"
      ],
      [
         "48",
         "Zenaida Frank",
         "Software Engineer",
         "New York",
         "7439",
         "2010/01/04",
         "$125,250"
      ],
      [
         "49",
         "Zorita Serrano",
         "Software Engineer",
         "San Francisco",
         "4389",
         "2012/06/01",
         "$115,000"
      ],
      [
         "50",
         "Jennifer Acosta",
         "Junior Javascript Developer",
         "Edinburgh",
         "3431",
         "2013/02/01",
         "$75,650"
      ],
      [
         "51",
         "Cara Stevens",
         "Sales Assistant",
         "New York",
         "3990",
         "2011/12/06",
         "$145,600"
      ],
      [
         "52",
         "Hermione Butler",
         "Regional Director",
         "London",
         "1016",
         "2011/03/21",
         "$356,250"
      ],
      [
         "53",
         "Lael Greer",
         "Systems Administrator",
         "London",
         "6733",
         "2009/02/27",
         "$103,500"
      ],
      [
         "54",
         "Jonas Alexander",
         "Developer",
         "San Francisco",
         "8196",
         "2010/07/14",
         "$86,500"
      ],
      [
         "55",
         "Shad Decker",
         "Regional Director",
         "Edinburgh",
         "6373",
         "2008/11/13",
         "$183,000"
      ],
      [
         "56",
         "Michael Bruce",
         "Javascript Developer",
         "Singapore",
         "5384",
         "2011/06/27",
         "$183,000"
      ],
      [
         "57",
         "Donna Snider",
         "Customer Support",
         "New York",
         "4226",
         "2011/01/25",
         "$112,000"
      ]
   ]
}


    respond_to do |format|
      format.html { render "employers/employer_profiles/binder_index" }
      format.js {}
    end
  end

  def employer_index
    @q = params.permit(:q)[:q]
    @orgs = Organization.search(@q).exists(employer_profile: true)
    @page_alphabets = page_alphabets(@orgs, "legal_name")
    page_no = cur_page_no(@page_alphabets.first)
    @organizations = @orgs.where("legal_name" => /^#{page_no}/i)

    @employer_profiles = @organizations.map {|o| o.employer_profile}

    respond_to do |format|
      format.html { render "employers/employer_profiles/index" }
      format.js {}
    end
  end

  def staff_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(:$or => [{csr_role: {:$exists => true}}, {assister_role: {:$exists => true}}])
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end
  end

  def assister_index
    @q = params.permit(:q)[:q]
    @staff = Person.where(assister_role: {:$exists =>true})
    @page_alphabets = page_alphabets(@staff, "last_name")
    page_no = cur_page_no(@page_alphabets.first)
    if @q.nil?
      @staff = @staff.where(last_name: /^#{page_no}/i)
    else
      @staff = @staff.where(last_name: @q)
    end
  end

  def find_email(agent, role)
    if role == 'Broker'
      agent.try(:broker_role).try(:email).try(:address)
    else
      agent.try(:user).try(:email)
    end
  end

  def request_help
    role = nil
    if params[:type]
      cac_flag = params[:type] == 'CAC'
      match = CsrRole.find_by_name(params[:firstname], params[:lastname], cac_flag)
      if match.count > 0
        agent = match.first
        role = cac_flag ? 'Certified Applicant Counselor' : 'Customer Service Representative'
      end
    else
      if params[:broker].present?
        agent = Person.find(params[:broker])
        broker_role_id = agent.broker_role.id
        consumer = Person.find(params[:person])
        family = consumer.primary_family
        family.hire_broker_agency(broker_role_id)
        role = 'Broker'
      else
        agent = Person.find(params[:assister])
        role = 'In-Person Assister'
      end
    end
    if role
      status_text = 'Message sent to ' + role + ' ' + agent.full_name + ' <br>' 
      if find_email(agent, role)
        agent_assistance_messages(params,agent,role)
      else

        status_text = "Agent has no email.   Please select another"
      end
    else
      status_text = call_customer_service params[:firstname].strip, params[:lastname].strip
    end
    @person = Person.find(params[:person])
    broker_view = render_to_string 'insured/families/_consumer_brokers_widget', :layout => false
    render :text => {broker: broker_view, status: status_text}.to_json, layout: false
  end

  def family_index
    @q = params.permit(:q)[:q]
    page_string = params.permit(:families_page)[:families_page]
    page_no = page_string.blank? ? nil : page_string.to_i
    unless @q.present?
      @families = Family.page page_no
      @total = Family.count
    else
      total_families = Person.search(@q).map(&:families).flatten.uniq
      @total = total_families.count
      @families = Kaminari.paginate_array(total_families).page page_no
    end
    respond_to do |format|
      format.html { render "insured/families/index" }
      format.js {}
    end
  end

  def broker_agency_index
    @broker_agency_profiles = BrokerAgencyProfile.all

    respond_to do |format|
      format.html { render "broker" }
      format.js {}
    end
  end

  def issuer_index
    @issuers = CarrierProfile.all

    respond_to do |format|
      format.html { render "issuer_index" }
      format.js {}
    end
  end

  def product_index
    respond_to do |format|
      format.html { render "product_index" }
      format.js {}
    end
  end

  def configuration
    @time_keeper = Forms::TimeKeeper.new

    respond_to do |format|
      format.html { render partial: "configuration_index" }
      format.js {}
    end
  end

  # GET /exchanges/hbx_profiles/1
  # GET /exchanges/hbx_profiles/1.json
  def show
    if current_user.has_csr_role? || current_user.try(:has_assister_role?)
      redirect_to home_exchanges_agents_path
      return
    else 
      unless current_user.has_hbx_staff_role?
        redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
        return
      end
    end
    session[:person_id] = nil
    @unread_messages = @profile.inbox.unread_messages.try(:count) || 0
  end

  # GET /exchanges/hbx_profiles/new
  def new
    @organization = Organization.new
    @hbx_profile = @organization.build_hbx_profile
  end

  # GET /exchanges/hbx_profiles/1/edit
  def edit
  end

  # GET /exchanges/hbx_profiles/1/inbox
  def inbox
    @inbox_provider = current_user.person.hbx_staff_role.hbx_profile
    @folder = params[:folder] || 'inbox'
    @sent_box = true
  end

  # POST /exchanges/hbx_profiles
  # POST /exchanges/hbx_profiles.json
  def create
    @organization = Organization.new(organization_params)
    @hbx_profile = @organization.build_hbx_profile(hbx_profile_params.except(:organization))

    respond_to do |format|
      if @hbx_profile.save
        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully created.' }
        format.json { render :show, status: :created, location: @hbx_profile }
      else
        format.html { render :new }
        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /exchanges/hbx_profiles/1
  # PATCH/PUT /exchanges/hbx_profiles/1.json
  def update
    respond_to do |format|
      if @hbx_profile.update(hbx_profile_params)
        format.html { redirect_to exchanges_hbx_profile_path @hbx_profile, notice: 'HBX Profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @hbx_profile }
      else
        format.html { render :edit }
        format.json { render json: @hbx_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /exchanges/hbx_profiles/1
  # DELETE /exchanges/hbx_profiles/1.json
  def destroy
    @hbx_profile.destroy
    respond_to do |format|
      format.html { redirect_to exchanges_hbx_profiles_path, notice: 'HBX Profile was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def set_date
    forms_time_keeper = Forms::TimeKeeper.new(params[:forms_time_keeper])
    begin
      forms_time_keeper.set_date_of_record(forms_time_keeper.forms_date_of_record)
      flash[:notice] = "Date of record set to " + TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    rescue Exception=>e
      flash[:error] = "Failed to set date of record, " + e.message
    end
    redirect_to exchanges_hbx_profiles_root_path
  end

private
  def agent_assistance_messages(params, agent, role)
    if params[:person].present?
      insured = Person.find(params[:person])
      first_name = insured.first_name
      last_name = insured.last_name
      name = insured.full_name
      insured_email = insured.emails.last.try(:address) || insured.try(:user).try(:email)
      root = 'http://' + request.env["HTTP_HOST"]+'/exchanges/agents/resume_enrollment?person_id=' + params[:person] +'&original_application_type:'
      body = 
        "Please contact #{insured.first_name} #{insured.last_name}. <br/> " + 
        "Plan Shopping help request from Person Id #{insured.id}, email #{insured_email}.<br/>" +
        "Additional PII is SSN #{insured.ssn} and DOB #{insured.dob}.<br>" +
        "<a href='" + root+"phone'>Assist Customer</a>  <br>" 
    else
      first_name = params[:first_name]
      last_name = params[:last_name]
      name = first_name.to_s + ' ' + last_name.to_s 
      insured_email = params[:email]
      body =  "Please contact #{first_name} #{last_name}. <br/>" +
        "Plan shopping help has been requested by #{insured_email}<br>"
      body += "SSN #{params[:ssn]} <br>" if params[:ssn].present?
      body += "DOB #{params[:dob]} <br>" if params[:dob].present?
    end
    hbx_profile = HbxProfile.find_by_state_abbreviation('DC')
    message_params = {
      sender_id: hbx_profile.id,
      parent_message_id: hbx_profile.id,
      from: 'Plan Shopping Web Portal',
      to: "Agent Mailbox",
      subject: "Please contact #{first_name} #{last_name}. ",
      body: body,
      }
    create_secure_message message_params, hbx_profile, :sent
    create_secure_message message_params, agent, :inbox
    result = UserMailer.new_client_notification(find_email(agent,role), first_name, name, role, insured_email, params[:person].present?)
    result.deliver_now
    puts result.to_s if Rails.env.development?
   end  

  def find_hbx_profile
    @profile = current_user.person.try(:hbx_staff_role).try(:hbx_profile)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_hbx_profile
    @hbx_profile = HbxProfile.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def organization_params
    params[:hbx_profile][:organization].permit(:organization_attributes)
  end

  def hbx_profile_params
    params[:hbx_profile].permit(:hbx_profile_attributes)
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

  def check_csr_or_hbx_staff
    unless current_user.has_hbx_staff_role? || (current_user.person.csr_role && !current_user.person.csr_role.cac)
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member or a CSR" }
    end
  end

  def authorize_for_instance
    authorize @hbx_profile, "#{action_name}?".to_sym 
  end

  def call_customer_service(first_name, last_name)
    "No match found for #{first_name} #{last_name}.  Please call Customer Service at: (855)532-5465 for assistance.<br/>"
  end
end
