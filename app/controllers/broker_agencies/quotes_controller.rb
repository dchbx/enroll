class BrokerAgencies::QuotesController < ApplicationController

  include BrokerAgencies::QuoteHelper

  before_action :validate_roles, :set_broker_role
  before_action :find_quote , :only => [:destroy ,:show, :delete_member, :delete_household, :publish_quote, :view_published_quote]
  before_action :format_date_params  , :only => [:update,:create]
  before_action :employee_relationship_map
  before_action :set_qhp_variables, :only => [:plan_comparison, :download_pdf]

  def view_published_quote

  end

  def publish_quote
    if @quote.may_publish?
      @quote.publish!
      flash[:notice] = "Quote Published"
    else
      errors = @quote.quote_warnings.values
      flash[:error] = "Quote failed to publish. #{('<li>' + errors.flatten.join('</li><li>') + '</li>') if errors.try(:any?)}".html_safe
      redirect_to broker_agencies_broker_role_quote_path(params[:broker_role_id],params[:id])
    end
  end

  # displays index page of quotes
  def my_quotes
    @all_quotes = Quote.where("broker_role_id" => @broker.id)
    Effective::Datatables::QuoteDatatable.broker_role_id = @broker.id
    @datatable = Effective::Datatables::QuoteDatatable.new
    respond_to do |format|
      format.js
      format.html {render 'quotes'}
    end
  end

  def show 
    @q = Quote.find(params[:id])
    @benefit_groups = @q.quote_benefit_groups
    @quote_benefit_group = (params[:benefit_group_id] && @q.quote_benefit_groups.find(params[:benefit_group_id])) || @benefit_groups.first

    #active_year = Date.today.year
    @coverage_kind = "health"
    @section = !params[:section].present?
    @index = params[:row].to_i

    @health_plans = Plan.shop_health_plans @q.plan_year
    @health_selectors = Plan.build_plan_selectors('shop', 'health', @q.plan_year)
    @health_plan_quote_criteria  = Plan.build_plan_features('shop', 'health', @q.plan_year).to_json
    @dental_plans = Plan.shop_dental_plans @q.plan_year
    @dental_selectors = Plan.build_plan_selectors('shop', 'dental', @q.plan_year)
    dental_plan_quote_criteria  = Plan.build_plan_features('shop', 'dental',@q.plan_year) .to_json
    @dental_plans_count = @dental_plans.count

    @bp_hash = {'employee':50, 'spouse': 0, 'domestic_partner': 0, 'child_under_26': 0, 'child_26_and_over': 0}
    @benefit_pcts_json = @bp_hash.to_json
    @quote_criteria = []

    @quote_benefit_group.quote_relationship_benefits.each{|bp| @bp_hash[bp.relationship] = bp.premium_pct}
    roster_premiums = @quote_benefit_group.roster_cost_all_plans
    @roster_premiums_json = roster_premiums.to_json
    dental_roster_premiums =  @quote_benefit_group.roster_cost_all_plans('dental')
    @dental_roster_premiums = dental_roster_premiums.to_json
    @quote_criteria = @quote_benefit_group.criteria_for_ui
    @benefit_pcts_json = @bp_hash.to_json
    unless @section
    respond_to do |format|
        format.js
    end
    end
  end

  def health_cost_comparison
    get_health_cost_comparison({quote_id: params[:quote_id], benefit_id: params[:benefit_id], plan_ids: params['plans']})
    render partial: 'health_cost_comparison'
  end

  def dental_cost_comparison
    get_dental_cost_comparison({quote_id: params[:quote_id], benefit_id: params[:benefit_id], plan_ids: params['plans']})
    render partial: 'dental_cost_comparison', layout: false
  end

  # no longer use?
  # def add_family
  #   @qhh = Quote.all.first.quote_households.first
  #   @quote = Quote.find(@qhh.quote)
  #   respond_to do |format|
  #     format.js
  #   end
  # end

  def edit
    #find quote to edit
    @quote = Quote.find(params[:id])
    broker_role_id = @quote.broker_role.id
    @orgs = Organization.by_broker_role(broker_role_id)
    @employer_profiles =  @orgs.blank? ? [] : @orgs.map {|o| o.employer_profile}.collect{|e| [e.legal_name, e.id]}
    max_family_id = @quote.quote_households.max(:family_id).to_i

    unless params[:duplicate_household].blank? && params[:num_of_dup].blank?
      dup_household = @quote.quote_households.find(params[:duplicate_household]).dup

      for i in 1..params[:num_of_dup].to_i
        temp_household = dup_household.dup
        max_family_id = max_family_id + 1
        temp_household.family_id = max_family_id
        @quote.quote_households << temp_household
      end
    end

    # Create place holder for a new benefit group
    qbg = QuoteBenefitGroup.new

    # Create place holder for a new household and new member for the roster
    qhh = QuoteHousehold.new

    # Increment family id so the new place holder contains max + 1
    qhh.family_id = max_family_id + 1
    # Create place holder for new member of household
    if params[:new_family].present?
      qm = QuoteMember.new
      qhh.quote_members << qm
      @quote.quote_households << qhh
    end
    @quote_benefit_group_dropdown = @quote.quote_benefit_groups.dup
    @quote.quote_benefit_groups << qbg


    @scrollTo = params[:scrollTo] == "1" ? 1 : 0

    flash.now[:notice] = "This quote has been published and no editing is allowed." if @quote.is_complete?
    #redirect_to edit_broker_agencies_quote_path(@quote.id)

  end

  def new
    quote = Quote.new
    # Build Default Quote Benefit Group
    qbg = QuoteBenefitGroup.new
    qbg.title = "Default Benefit Package"
    quote.quote_benefit_groups << qbg
    # Assign new quote to current broker
    quote.broker_role_id= @broker.id

    quote.save(validate: false)
    redirect_to edit_broker_agencies_broker_role_quote_path(@broker.id, quote.id)
  end

  def update
    @quote = Quote.find(params[:id])

    sanitize_quote_roster_params

    # update current attributs then insert new ones. Both can't be done at the same time.
    update_params = quote_params
    insert_params = quote_params
    if update_params[:quote_households_attributes]
      update_params[:quote_households_attributes] = update_params[:quote_households_attributes].select {|k,v| update_params[:quote_households_attributes][k][:id].present?}
      insert_params[:quote_households_attributes] = insert_params[:quote_households_attributes].select {|k,v| insert_params[:quote_households_attributes][k][:id].blank?}
    end
    if update_params[:quote_benefit_groups_attributes]
      update_params[:quote_benefit_groups_attributes] = update_params[:quote_benefit_groups_attributes].select {|k,v| update_params[:quote_benefit_groups_attributes][k][:id].present?}
      insert_params[:quote_benefit_groups_attributes] = insert_params[:quote_benefit_groups_attributes].select {|k,v| insert_params[:quote_benefit_groups_attributes][k][:id].blank?}
    end
    if params[:commit] == "Add Employee"
      new_family = true
      notice_message = "New employee added."
      scrollTo = 1
    elsif params[:commit] == "Save Changes"
      new_family = nil
      notice_message = "Successfully saved quote/employee roster."
      scrollTo = 0
    elsif params[:commit] == "Save"
      new_family = @quote.quote_households.count > 0 ? '' : true
    end
    if (params[:quote][:employer_type] == 'prospect' && @quote.employer_type != 'prospect') || (params[:quote][:employer_type] == 'client' && @quote.employer_profile_id != params[:employer_profile_id])
      @quote.quote_households if @quote.quote_households.present?
      @quote.update_attributes(employer_profile_id: nil)
    end
    if (@quote.update_attributes(update_params) && @quote.update_attributes(insert_params))
      duplicate_household = @quote.quote_households.where(family_id: params[:duplicate_household]).first.try(:id).try(:to_str)
      num_of_dup = duplicate_household ? params[:num_of_dup] : nil
      if params[:commit] == "Create Quote"
        redirect_to broker_agencies_broker_role_quote_path(params[:broker_role_id],params[:id])
      else
        redirect_to edit_broker_agencies_broker_role_quote_path(@broker.id, @quote, new_family: new_family, scrollTo: scrollTo,duplicate_household: duplicate_household ,num_of_dup: num_of_dup),  :flash => { :notice => notice_message }
      end
    else
      redirect_to edit_broker_agencies_broker_role_quote_path(@broker.id, @quote) ,  :flash => { :error => "Unable to update the employee roster." }
    end
  end

  def create
    @quote = Quote.new(quote_params)
    @quote.broker_role_id= @broker.id
    if @format_errors.present?
      flash[:error]= "#{@format_errors.join(', ')}"
      render "new"  and return
    end
    if @quote.save
      redirect_to  edit_broker_agencies_broker_role_quote_path(@broker.id, @quote),:flash => { :notice => "Successfully saved quote/employee roster." }
    else
      flash[:error]="Unable to save the employee roster : #{@quote.errors.full_messages.join(", ")}"
      render "new"
    end
  end

  def plan_comparison
    standard_component_ids = get_standard_component_ids
    @qhps = Products::QhpCostShareVariance.find_qhp_cost_share_variances(standard_component_ids, @active_year, "Health")
    @sort_by = params[:sort_by].rstrip
    # Sorting by the same parameter alternates between ascending and descending
    @order = @sort_by == session[:sort_by_copay] ? -1 : 1
    session[:sort_by_copay] = @order == 1 ? @sort_by : ''
    if @sort_by && @sort_by.length > 0
      @sort_by = @sort_by.strip
      sort_array = []
      @qhps.each do |qhp|
        sort_array.push( [qhp, get_visit_cost(qhp,@sort_by)]  )
      end
      sort_array.sort!{|a,b| a[1]*@order <=> b[1]*@order}
      @qhps = sort_array.map{|item| item[0]}
    end
    render partial: 'plan_comparision', layout: false, locals: {qhps: @qhps}
  end

  def build_employee_roster
    @employee_roster = parse_employee_roster_file
    @quote= Quote.find(params[:id])
    broker_role_id = @quote.broker_role.id
    @orgs = Organization.by_broker_role(broker_role_id)
    @employer_profiles = @orgs.map {|o| o.employer_profile} unless @orgs.blank?
    @quote_benefit_group_dropdown = @quote.quote_benefit_groups
    if @employee_roster.is_a?(Hash)
      @employee_roster.each do |family_id , members|
        @quote_household = @quote.quote_households.where(:family_id => family_id).first
        @quote_household= QuoteHousehold.new(:family_id => family_id ) if @quote_household.nil?
        members.each do |member|
          @quote_members= QuoteMember.new(:employee_relationship => member[0], :dob => member[1], :last_name => member[2], :first_name => member[3])
          @quote_household.quote_members << @quote_members
        end
        @quote.quote_households << @quote_household
        @quote.save!
      end
    end
    redirect_to edit_broker_agencies_broker_role_quote_path(@broker.id, @quote)
  end

  def upload_employee_roster
    @quote = Quote.find(params[:id])
    emp = params[:type] == 'prospect' ? { employer_name: params[:name] } : {employer_profile_id: params[:profile_id]}
    @quote.update_attributes({employer_type: params[:type], start_on: params[:effective_date], quote_name: params[:quote_name]}.merge(emp))
  end

  def download_employee_roster
    @quote = Quote.find(params[:id])
    @employee_roster = @quote.quote_households.map(&:quote_members).flatten
    send_data(csv_for(@employee_roster), :type => 'text/csv; charset=iso-8859-1; header=present',
    :disposition => "attachment; filename=Employee_Roster.csv")
  end

  def delete_quote_modal
    @row = params[:row]
    @quote = Quote.find(params[:id])
    respond_to do |format|
      format.js {
        render "datatables/delete_quote_modal"
      }
    end
  end

  def delete_quote
    @quote = Quote.find(params[:id])
    if @quote.destroy
      flash[:notice] = "Successfully deleted #{@quote.quote_name}."
      respond_to do |format|
        format.html {
          redirect_to my_quotes_broker_agencies_broker_role_quotes_path(@broker)
        }
      end
    end
  end

  def delete_member
    if @quote.is_complete?
      render :text => "false", :format => :js
      return
    end
    @qh = @quote.quote_households.find(params[:household_id])
    if @qh
      if @qh.quote_members.find(params[:member_id]).delete
        respond_to do |format|
          format.js { render :nothing => true}
        end
      end
    end
  end

  def delete_household
    #render :text => "false", :format => :js if @quote.is_complete?
    @qh = @quote.quote_households.find(params[:household_id])
    if @qh.destroy
      respond_to do |format|
        format.js { render :nothing => true }
      end
    end
  end

  def delete_benefit_group

    quote_benefit_group = QuoteBenefitGroup.find(params[:quote_benefit_group_id])

    if quote_benefit_group.is_assigned?
      render :text => "false", :format => :js
      return
    else
      quote_benefit_group.destroy
    end

    respond_to do |format|
        format.js { render :nothing => true }
      end
  end

  def new_household
    @quote = Quote.new
    @quote.quote_households.build
  end

  def update_benefits
    benefit_group = Quote.find(params[:quote_id]).quote_benefit_groups.find(params[:benefit_id])
    return false if benefit_group.quote.is_complete?
    benefits = params[:benefits]
    relationship_benefits = params[:coverage_kind] != 'dental' ?  benefit_group.quote_relationship_benefits : benefit_group.quote_dental_relationship_benefits
    relationship_benefits.each {|b| b.update_attributes!(premium_pct: benefits[b.relationship]) }
    render json: {}
  end

  def get_quote_info
    bp_hash = {}
    bp_dental_hash = {}
    quote = Quote.find(params[:quote_id])
    benefit_groups = quote.quote_benefit_groups
    bg = (params[:benefit_group_id] && quote.quote_benefit_groups.find(params[:benefit_group_id])) || benefit_groups.first
    summary = {name: quote.quote_name,
     status: quote.aasm_state.capitalize,
     plan_name: bg.plan && bg.plan.name || 'None',
     dental_plan_name: "bg.dental_plan && bg.dental_plan.name" || 'None',
    }
    bg.quote_relationship_benefits.each{|bp| bp_hash[bp.relationship] = bp.premium_pct}
    bg.quote_dental_relationship_benefits.each{|bp| bp_dental_hash[bp.relationship] = bp.premium_pct}
    render json: {
                  'relationship_benefits' => bp_hash,
                  'dental_relationship_benefits' => bp_dental_hash,
                  'roster_premiums' => bg.roster_cost_all_plans,
                  'dental_roster_premiums' => bg.roster_cost_all_plans('dental'),
                  'criteria' => JSON.parse(bg.criteria_for_ui),
                  'summary' => summary}
  end

  def set_plan
    @q = Quote.find(params[:quote_id])

    bg = (params[:benefit_group_id] && @q.quote_benefit_groups.find(params[:benefit_group_id]))

    if params[:plan_id] && bg
      plan = Plan.find(params[:plan_id][8,100])
      if params[:coverage_kind]  != 'dental'
        elected_plan_choice = ['na', 'Single Plan', 'Single Carrier', 'Metal Level'][params[:elected].to_i]
        bg.plan = plan
        bg.plan_option_kind = elected_plan_choice
        bg.elected_health_plan_ids = params[:elected_plans_list]
        roster_elected_plan_bounds = PlanCostDecoratorQuote.elected_plans_cost_bounds(Plan.shop_health_plans(@q.plan_year),
           bg.quote_relationship_benefits, bg.roster_cost_all_plans('health'))
        case elected_plan_choice
          when 'Single Carrier'
            bg.plan_option_kind = "single_carrier"
            bg.published_lowest_cost_plan = roster_elected_plan_bounds[:carrier_low_plan][plan.carrier_profile.abbrev]
            bg.published_highest_cost_plan = roster_elected_plan_bounds[:carrier_high_plan][plan.carrier_profile.abbrev]
          when 'Metal Level'
            bg.plan_option_kind = "metal_level"
            bg.published_lowest_cost_plan = roster_elected_plan_bounds[:metal_low_plan][plan.metal_level]
            bg.published_highest_cost_plan = roster_elected_plan_bounds[:metal_high_plan][plan.metal_level]
          else
            bg.plan_option_kind = "single_plan"
            bg.published_lowest_cost_plan = plan.id
            bg.published_highest_cost_plan = plan.id
        end
      else
        column_for_dental_plan_option_kind = params[:elected].to_i # col 3 is custom, col 1 is single
        elected_plan_choice = ['na', 'single_plan', 'single_carrier', 'single_plan'][params[:elected].to_i]
        bg.dental_plan_option_kind = elected_plan_choice
        bg.dental_plan = plan
        bg.elected_dental_plan_ids = params[:elected_plans_list]
        # bg.elected_dental_plan_ids = case column_for_dental_plan_option_kind.to_i
        # when 1
        #  [plan.id]
        # when 2
        #  [plan.id]
        # else
        #   params[:elected_plans_list].map{|plan_id| Plan.find(plan_id).id}
        # end
      end
      bg.save
    end
    @benefit_groups = @q.quote_benefit_groups
    respond_to do |format|
      format.html {render partial: 'publish'}
      format.pdf do
          render :pdf => "publised_quote",
                 :template => "/broker_agencies/quotes/_publish.pdf.erb"
      end
    end
  end

  def copy
    @q = Quote.find(params[:quote_id])
    @q.clone
  end

  def publish
    @q = Quote.find(params[:quote_id])
    @benefit_groups = @q.quote_benefit_groups
    respond_to do |format|
      format.html {render partial: 'publish'}
      format.pdf do
          render :pdf => "publised_quote",
                 :template => "/broker_agencies/quotes/_publish.pdf.erb"
      end
    end
  end

  def criteria
    benefit_group = Quote.find(params[:quote_id]).quote_benefit_groups.find(params[:benefit_id])
    return false if benefit_group.quote.is_complete?
    criteria_for_ui = params[:criteria_for_ui]
    deductible_for_ui = params[:deductible_for_ui]
    benefit_group.update_attributes!(criteria_for_ui: criteria_for_ui ) if criteria_for_ui
    benefit_group.update_attributes(deductible_for_ui: deductible_for_ui) if deductible_for_ui
    render json: JSON.parse(benefit_group.criteria_for_ui)
  end

  def download_pdf
    standard_component_ids = get_standard_component_ids
    @qhps = Products::QhpCostShareVariance.find_qhp_cost_share_variances(standard_component_ids, @active_year, "Health")
    render pdf: 'plan_comparison_export',
           template: 'broker_agencies/quotes/_plan_comparison_export.html.erb',
           disposition: 'attachment',
           locals: { qhps: @qhps }
  end

  def dental_plans_data
    set_dental_plans
    render partial: 'my_dental_plans'
  end

  def employees_list
 
    employer_profile = EmployerProfile.find(params[:employer_profile_id])
    quote = Quote.find(params[:quote_id])
    @quote_benefit_group_dropdown = quote.quote_benefit_groups

    unless employer_profile.blank?
      @employees = employer_profile.census_employees.non_terminated

      @quote = Quote.new
      # # Create place holder for new member of household
      households = quote.quote_households.destroy_all
      @employees.each do |x|
       max_family_id = @quote.quote_households.max(:family_id).to_i
       qhh = QuoteHousehold.new(family_id: max_family_id + 1)
       qhh.quote_members << QuoteMember.new(dob: x.dob, first_name: x.first_name, last_name:x.last_name)
       @quote.quote_households << qhh
      end
       @employee_present = true
    else
      tmp_households
      @employee_present = false
    end
    respond_to do |format|
      # format.html 
      format.js
    end  
  end

  def employee_type
    @quote= Quote.find(params[:id])
    broker_role_id = @quote.broker_role.id
    @orgs = Organization.by_broker_role(broker_role_id)
    @employer_profiles =  @orgs.blank? ? [] : @orgs.map {|o| o.employer_profile}.collect{|e| [e.legal_name, e.id]}
    @employee_type = params[:type]
    if @quote.employer_type == 'client' && params[:type] == 'prospect'
      @quote.quote_households.destroy_all
    end
  end


private

  def set_broker_role
    @broker = BrokerRole.find(params[:broker_role_id])
  end

  def quote_download_link(quote)
    return quote.published? ? view_context.link_to("Download PDF" , publish_broker_agencies_broker_role_quotes(:format => :pdf,:quote_id => quote.id)) : ""
  end

  def employee_relationship_map
    @employee_relationship_map = {"employee" => "Employee", "spouse" => "Spouse", "domestic_partner" => "Domestic Partner", "child_under_26" => "Child"}
  end

  def get_standard_component_ids
    Plan.where(:_id => { '$in': params[:plans] } ).map(&:hios_id)
  end

  def quote_params
    params.require(:quote).permit(
                    :quote_name,
                    :start_on,
                    :broker_role_id,
                    :employer_type,
                    :employer_name,
                    :employer_profile_id,
                    :quote_benefit_groups_attributes => [:id, :title],
                    :quote_households_attributes => [ :id, :family_id , :quote_benefit_group_id,
                                       :quote_members_attributes => [ :id, :first_name, :last_name ,:dob,
                                                                      :employee_relationship,:_delete ] ] )
  end

  def format_date_params
    @format_errors=[]
    params[:quote][:start_on] =  Date.strptime(params[:quote][:start_on],"%Y-%m-%d") if params[:quote][:start_on]
    if params[:quote][:quote_households_attributes]
      params[:quote][:quote_households_attributes].values.each do |household_attribute|
        if household_attribute[:quote_members_attributes].present?
          household_attribute[:quote_members_attributes].values.map do |m|
            begin
              m[:dob] = Date.strptime(m[:dob],"%m/%d/%Y") unless m[:dob] && m[:dob].blank?
            rescue Exception => e
              @format_errors << "Error parsing date #{m[:dob]}"
            end
          end
        end
      end
    end
  end



  def sanitize_quote_roster_params
    if params[:quote][:quote_benefit_groups_attributes].present?
      params[:quote][:quote_benefit_groups_attributes].each do |k,v|
        #do not save if no data was entered for benefit group
        if v["title"].blank?
          params[:quote][:quote_benefit_groups_attributes].delete(k)
        end
      end
    end

    if params[:quote][:quote_households_attributes].present?
      params[:quote][:quote_households_attributes].each do |key, fid|
        delete_family_key = 1
        unless params[:quote][:quote_households_attributes][key][:quote_members_attributes].nil?
          params[:quote][:quote_households_attributes][key][:quote_members_attributes].each do |k, mid|
            if mid['dob'].blank?
                params[:quote][:quote_households_attributes][key][:quote_members_attributes].delete(k)
            else
              delete_family_key = 0
            end
          end
          params[:quote][:quote_households_attributes].delete(key) if delete_family_key == 1
        else
          params[:quote][:quote_households_attributes].delete(key)
        end
      end
    end
  end

  def employee_roster_group_by_family_id
    params[:employee_roster].inject({}) do  |new_hash,e|
      new_hash[e[1][:family_id]].nil? ? new_hash[e[1][:family_id]] = [e[1]]  : new_hash[e[1][:family_id]] << e[1]
      new_hash
    end
  end

  def find_quote
    @quote = Quote.find(params[:id])
  end

  # TODO JIM Is this used anywhere?
  def find_benefit_group
    @benefit_group = QuoteBenefitGroup.find(params[:id])
  end

  # def parse_employee_roster_file
  #   begin
  #     CSV.parse(params[:employee_roster_file].read) if params[:employee_roster_file].present?
  #   rescue Exception => e
  #     flash[:error] = "Unable to parse the csv file"
  #     #redirect_to :action => "new" and return
  #   end
  # end

  def parse_employee_roster_file
    begin
      roster = Roo::Spreadsheet.open(params[:employee_roster_file])
      sheet = roster.sheet(0)
      sheet_header_row = sheet.row(1)
      column_header_row = sheet.row(2)
      census_employees = {}
      (4..sheet.last_row).each_with_index.map do |i, index|
        row = roster.row(i)
        row[1]="child_under_26" if row[1].downcase == "child"
        if census_employees[row[0].to_i].nil?
          census_employees[row[0].to_i] = [[row[1].split.join('_').downcase,row[8],row[2],row[3]]]
        else
          census_employees[row[0].to_i] << [row[1].split.join('_').downcase,row[8],row[2],row[3]]
        end
      end
      census_employees
    rescue Exception => e
      puts e.message
      flash[:error] = "Unable to parse the csv file"
      #redirect_to :action => "new" and return
    end
  end

  def csv_for(employee_roster)
    (output = "").tap do
      CSV.generate(output) do |csv|
        csv << ["FamilyID", "FirstName", "LastName", "Relationship", "DOB"]
        employee_roster.each do |employee|
          csv << [  employee.quote_household.family_id,
                    employee.first_name,
                    employee.last_name,
                    employee.employee_relationship,
                    employee.dob
                  ]
        end
      end
    end
  end

  def dollar_value copay
    return 10000 if copay == 'Not Applicable'
    cost = 0
    cost += 1000 if copay.match(/after deductible/)
    return cost if copay.match(/No charge/)
    dollars = copay.match(/(\d+)/)
    cost += (dollars && dollars[1]).to_i || 0
  end

  def get_visit_cost qhp_cost_share_variance, visit_type
    service_visit = qhp_cost_share_variance.qhp_service_visits.detect{|v| visit_type == v.visit_type }
    cost = dollar_value service_visit.copay_in_network_tier_1
  end

  def set_qhp_variables
    @quote = Quote.find(params['quote_id'])
    @active_year = @quote.plan_year
    @coverage_kind = "health"
    @visit_types = @coverage_kind == "health" ? Products::Qhp::VISIT_TYPES : Products::Qhp::DENTAL_VISIT_TYPES
  end

  def set_dental_plans
    @dental_plans = Plan.shop_dental_by_active_year(2017)
    @dental_plans_count = Plan.shop_dental_by_active_year(2017).count
    carrier = params[:carrier_id].nil? ? [] : params[:carrier_id]
    dental_level = params[:dental_level].nil? ? [] : params[:dental_level]
    plan_type = params[:plan_type].nil? ? [] : params[:plan_type]
    dc_network = params[:dc_network].nil?  ? [] : params[:dc_network]
    nationwide = params[:nationwide].nil? ? [] : params[:nationwide]
    @dental_plans = @dental_plans.by_carrier_profile_for_bqt(params[:carrier_id]) unless  carrier.empty? || carrier.include?('')
    @dental_plans = @dental_plans.by_dental_level_for_bqt(params[:dental_level])  unless  dental_level.empty? || dental_level.include?('')
    @dental_plans = @dental_plans.by_plan_type_for_bqt(params[:plan_type])   unless  plan_type.empty? || plan_type.include?('')
    @dental_plans = @dental_plans.by_dc_network(params[:dc_network])  unless  dc_network.empty? || dc_network.include?('')
    @dental_plans = @dental_plans.by_nationwide(params[:nationwide])  unless  nationwide.empty? || nationwide.include?('')
  end

  def validate_roles
    current_user.has_broker_role? || current_user.has_hbx_staff_role?
  end

  def tmp_households
    @quote = Quote.new
    qbg = QuoteBenefitGroup.new
    # Create place holder for a new household and new member for the roster
    qhh = QuoteHousehold.new
    # Increment family id so the new place holder contains max + 1
    max_family_id = @quote.quote_households.max(:family_id).to_i
    qhh.family_id = max_family_id + 1
    # Create place holder for new member of household
    qm = QuoteMember.new
    qhh.quote_members << qm
    @quote.quote_households << qhh
  end

end
