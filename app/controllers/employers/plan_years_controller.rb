class Employers::PlanYearsController < ApplicationController
  include Config::AcaConcern
  before_action :find_employer
  before_action :generate_carriers_and_plans, only: [:create, :reference_plan_options, :update, :edit]
  before_action :updateable?, only: [:new, :edit, :create, :update, :revert, :publish, :force_publish, :make_default_benefit_group]
  layout "two_column"

  def new
    @plan_year = build_plan_year
    if @employer_profile.constrain_service_areas? && @employer_profile.service_areas.blank?
      redirect_to employers_employer_profile_path(@employer_profile, :tab => "benefits"), :flash => { :error => no_products_message(@plan_year) }
    else
      @carriers_cache = CarrierProfile.all.inject({}){|carrier_hash, carrier_profile| carrier_hash[carrier_profile.id] = carrier_profile.legal_name; carrier_hash;}
    end
  end

  def dental_reference_plans
    @location_id = params[:location_id]
    @carrier_profile = params[:carrier_id]
    @benefit_group = params[:benefit_group]
    @is_edit = params[:is_edit]
    if @carrier_profile == 'all_plans'
      if @is_edit == "true"
        @elected_plans = @employer_profile.plan_years.find(params[:plan_year_id]).benefit_groups.find(params[:benefit_group]).elected_dental_plan_ids
      end
      @nav_option = params[:nav_option]
      @dental_plans = Plan.by_active_year(params[:start_on]).shop_market.dental_coverage
    else
      @dental_plans = Plan.by_active_year(params[:start_on]).shop_market.dental_coverage.by_carrier_profile(@carrier_profile)
    end
  end


  def reference_plans
    @benefit_group = params[:benefit_group]
    @plan_year = PlanYear.find(params[:plan_year_id])
    @location_id = params[:location_id]
    @dental_plans = Plan.by_active_year(params[:start_on]).shop_market.dental_coverage.all

    offering_query = Queries::EmployerPlanOfferings.new(@employer_profile)
    @plans = case params[:plan_option_kind]
    when "single_carrier"
      @carrier_id = params[:carrier_id]
      @carrier_profile = CarrierProfile.find(params[:carrier_id])
      offering_query.single_carrier_offered_health_plans(params[:carrier_id], params[:start_on])
    when "metal_level"
      @metal_level = params[:metal_level]
      offering_query.metal_level_offered_health_plans(params[:metal_level], params[:start_on])
    when "single_plan"
      @single_plan = params[:single_plan]
      @carrier_id = params[:carrier_id]
      @carrier_profile = CarrierProfile.find(params[:carrier_id])
      offering_query.single_option_offered_health_plans(params[:carrier_id], params[:start_on])
    when "sole_source"
      @single_plan = params[:single_plan]
      @carrier_id = params[:carrier_id]
      @carrier_profile = CarrierProfile.find(params[:carrier_id])
      offering_query.sole_source_offered_health_plans(params[:carrier_id], params[:start_on])
    end
    @carriers_cache = CarrierProfile.all.inject({}){|carrier_hash, carrier_profile| carrier_hash[carrier_profile.id] = carrier_profile.legal_name; carrier_hash;}
    respond_to do |format|
      format.js
    end
  end

  def reference_plan_summary
    @details = params[:details]
    @reference_plan_id = params[:ref_plan_id]
    @start_on = params[:start_on]
    @plan = Plan.find(@reference_plan_id) unless @reference_plan_id == nil
    @coverage_kind = params[:coverage_kind]
    @hios_id = params[:hios_id]
    hios_id = [] << params[:hios_id]
    @qhps = Products::QhpCostShareVariance.find_qhp_cost_share_variances(hios_id.to_a, params[:start_on], params[:coverage_kind])
    @visit_types = params[:coverage_kind] == "health" ? Products::Qhp::VISIT_TYPES : Products::Qhp::DENTAL_VISIT_TYPES
    @visit_types = @qhps.first.qhp_service_visits.map(&:visit_type) if params.has_key?(:details)
    respond_to do |format|
      format.js
    end
  end

  def plan_details
    @plan = Plan.find(params[:reference_plan_id])
    respond_to do |format|
      format.js
    end
  end

  def delete_benefit_group
    plan_year = PlanYear.find(params[:plan_year_id])
    if plan_year.benefit_groups.count > 1
      benefit_group = plan_year.benefit_groups.find(params[:benefit_group_id])
      benefit_group.disable_benefits

      if plan_year.save
        flash[:notice] = "Benefit Group: #{benefit_group.title} successfully deleted."
      end
    else
      flash[:error] = "Benefit package can not be deleted because it is the only benefit package remaining in the plan year."
    end
    render :js => "window.location = #{employers_employer_profile_path(@employer_profile, tab: 'benefits').to_json}"
  end

  def make_default_benefit_group
    plan_year = @employer_profile.plan_years.where(_id: params[:plan_year_id]).first
    if plan_year && benefit_group = plan_year.benefit_groups.where(_id: params[:benefit_group_id]).first

      if default_benefit_group = @employer_profile.default_benefit_group
        return if benefit_group == default_benefit_group
        default_benefit_group.default = false
      end

      benefit_group.default = true
      begin
        @employer_profile.save!
      rescue => e
        message = "There was an error setting the default benefit group because the employer profile failed validation."
        message = message + " employer_profile: #{@employer_profile}"
        @employer_profile.plan_years.each do |plan_year|
          message = message + " plan_year: #{plan_year}" unless plan_year.valid?
        end
        message = message + " stacktrace: #{e.backtrace}"
        log(message, {:severity => "error"})
        raise e
      end
    end
  end

  def create
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)

    @plan_year.benefit_groups.each_with_index do |benefit_group, i|
      benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
      benefit_group.elected_dental_plans = if benefit_group.dental_plan_option_kind == "single_plan"
        if i == 0
          ids = params["plan_year"]["benefit_groups_attributes"]["0"]["elected_dental_reference_plan_ids"]
        else
          @time = benefit_group.dental_relationship_benefits_attributes_time
          ids = params["plan_year"]["benefit_groups_attributes"]["#{@time}"]["elected_dental_reference_plan_ids"]
        end
        Plan.where(:id.in=> ids)
      else
        benefit_group.elected_dental_plans_by_option_kind
      end
      if benefit_group.sole_source?
        if benefit_group.composite_tier_contributions.empty?
          benefit_group.build_composite_tier_contributions
        end
        begin
          benefit_group.estimate_composite_rates
        rescue => e
          flash[:error] = ""
          benefit_group.errors[:composite_tier_contributions].each do |err|
            flash[:error] << err
          end
          render action: 'new'
          return
        end
      end
    end

    if @employer_profile.default_benefit_group.blank?
      @plan_year.benefit_groups[0].default= true
    end

    if @plan_year.save
      flash[:notice] = "Plan Year successfully created."
      redirect_to employers_employer_profile_path(@employer_profile.id, :tab=>'benefits')
    else
      render action: "new"
    end
  end

  def reference_plan_options
    @kind = params[:kind]
    @key = params[:key]
    @target = params[:target]
    plan_year = Date.parse(params["start_date"]).year unless params["start_date"].blank?
    @plans = case @kind
            when "carrier"
              Plan.valid_shop_health_plans("carrier", @key, plan_year)
            when "metal-level"
              Plan.valid_shop_health_plans("metal_level", @key, plan_year)
            else
              []
            end
  end

  def search_reference_plan
    @location_id = params[:location_id]
    @plan = Plan.find(params[:reference_plan_id])
    @premium_tables = @plan.premium_table_for(Date.parse(params[:start_on]))
  end

  def calc_employer_contributions
    @benefit_group_index = params[:benefit_group_index].to_i
    @location_id = params[:location_id]
    @plan = Plan.find(params[:reference_plan_id])
    @plan_option_kind = params[:plan_option_kind]
    params.merge!({ plan_year: { start_on: params[:start_on] }.merge(relationship_benefits) })
    @coverage_type = params[:coverage_type]
    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)

    coverage_type = 'health'
    if @coverage_type == '.dental'
      @plan_year.benefit_groups[0].dental_reference_plan = @plan
      coverage_type = 'dental'
    else
      @plan_year.benefit_groups[0].reference_plan = @plan
    end
    @plan_year.benefit_groups[0].build_estimated_composite_rates if @plan_option_kind == 'sole_source'

    @employer_contribution_amount = @plan_year.benefit_groups[0].monthly_employer_contribution_amount(@plan)
    @min_employee_cost = @plan_year.benefit_groups[0].monthly_min_employee_cost(coverage_type)
    @max_employee_cost = @plan_year.benefit_groups[0].monthly_max_employee_cost(coverage_type)
  end

  def calc_offered_plan_contributions

    @is_edit = params[:is_edit]
    @location_id = params[:location_id]
    @coverage_type = params[:coverage_type]
    @plan_option_kind = params[:plan_option_kind]
    @plan = Plan.find(params[:reference_plan_id])

    params.merge!({ plan_year: { start_on: params[:start_on] }.merge(relationship_benefits) })

    @hios_id = @plan.hios_id

    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)
    # @plan_year.benefit_groups[0].reference_plan = @plan

    coverage_type = 'health'
    if @coverage_type == '.dental'
      @plan_year.benefit_groups[0].dental_reference_plan = @plan
      coverage_type = 'dental'
    else
      @plan_year.benefit_groups[0].reference_plan = @plan
    end

    @plan_year.benefit_groups[0].build_estimated_composite_rates

    @employer_contribution_amount = @plan_year.benefit_groups[0].monthly_employer_contribution_amount(@plan)

    @min_employee_cost = @plan_year.benefit_groups[0].monthly_min_employee_cost(coverage_type)
    @max_employee_cost = @plan_year.benefit_groups[0].monthly_max_employee_cost(coverage_type)
  end

  def edit
    plan_year = @employer_profile.find_plan_year(params[:id])
    unless plan_year.products_offered_in_service_area
      redirect_to employers_employer_profile_path(@employer_profile, :tab => "benefits"), :flash => { :error => no_products_message(plan_year) }
      return
    end
    if params[:publish]
      @just_a_warning = !plan_year.is_application_eligible? ? true : false
      plan_year.application_warnings
    end
    @plan_year = ::Forms::PlanYearForm.new(plan_year)
    @plan_year.benefit_groups.each do |benefit_group|
      benefit_group.build_composite_tier_contributions if benefit_group.composite_tier_contributions.empty?
      benefit_group.build_relationship_benefits if benefit_group.relationship_benefits.empty?
      benefit_group.build_dental_relationship_benefits if benefit_group.dental_relationship_benefits.empty?
      case benefit_group.plan_option_kind
      when "metal_level"
        benefit_group.metal_level_for_elected_plan = benefit_group.elected_plans.try(:last).try(:metal_level)
      else
        benefit_group.carrier_for_elected_plan = benefit_group.elected_plans.try(:last).try(:carrier_profile_id)
      end
    end

    respond_to do |format|
      format.js { render 'edit' }
      format.html { render 'edit' }
    end
  end

  def update
    plan_year = @employer_profile.plan_years.where(id: params[:id]).last
    @plan_year = ::Forms::PlanYearForm.rebuild(plan_year, plan_year_params)
    @plan_year.benefit_groups.each_with_index do |benefit_group, i|
      benefit_group.elected_plans = benefit_group.elected_plans_by_option_kind
      ax = if benefit_group.dental_plan_option_kind == "single_plan"
        @i = i
        if benefit_group.elected_dental_plan_ids.blank?
          @time = benefit_group.dental_relationship_benefits_attributes_time
          ids = params["plan_year"]["benefit_groups_attributes"]["#{@time}"]["elected_dental_reference_plan_ids"]
        else
          ids = params["plan_year"]["benefit_groups_attributes"]["#{@i}"]["elected_dental_reference_plan_ids"]
        end
        ids ? Plan.where(:id.in=> ids) : nil
      else
        benefit_group.elected_dental_plans_by_option_kind
      end
      benefit_group.elected_dental_plans = ax if ax
      benefit_group.build_estimated_composite_rates
    end
    if @plan_year.save
      flash[:notice] = "Plan Year successfully saved."
      redirect_to employers_employer_profile_path(@employer_profile, :tab => "benefits")
    else
      redirect_to edit_employers_employer_profile_plan_year_path(@employer_profile, plan_year)
    end
  end

  def recommend_dates
    if params[:start_on].present?
      start_on = params[:start_on].to_date
      @result = PlanYear.check_start_on(start_on)
      if @result[:result] == "ok"
        @plan_year = build_plan_year
        @benefit_group = params[:benefit_group]
        @location_id = params[:location_id]
        @start_on = params[:start_on].to_date.year

        ## TODO: different if we dont have service areas enabled
        ## TODO: awfully slow
        @single_carriers = Organization.load_carriers(
                            primary_office_location: @employer_profile.organization.primary_office_location,
                            selected_carrier_level: 'single_carrier',
                            active_year: @start_on
                            )
        @sole_source_carriers = Organization.load_carriers(
                            primary_office_location: @employer_profile.organization.primary_office_location,
                            selected_carrier_level: 'sole_source',
                            active_year: @start_on
                            )
        @open_enrollment_dates = PlanYear.calculate_open_enrollment_date(start_on)
        @schedule= PlanYear.shop_enrollment_timetable(start_on)
      end
    end
  end

  def revert
    authorize EmployerProfile, :revert_application?
    @plan_year = @employer_profile.find_plan_year(params[:plan_year_id])
    if @employer_profile.plan_years.renewing.include?(@plan_year) && @plan_year.may_revert_renewal?
      @plan_year.revert_renewal
      if @plan_year.save
        flash[:notice] = "Plan Year successfully reverted from renewing to applicant."
      else
        application_errors = @plan_year.application_errors
        errors = @plan_year.errors.full_messages
        error_messages = application_errors.inject(""){|memo, error| "#{memo}<li>#{error[0]}: #{error[1].flatten.join(',')}</li>"} +
                         errors.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}

        flash[:error] = "Renewing Plan Year could not be reverted to draft. #{error_messages}".html_safe
      end
    elsif @employer_profile.plan_years.include?(@plan_year) && @plan_year.may_revert_application?
      @plan_year.revert_application
      if @plan_year.save
        flash[:notice] = "Plan Year successfully reverted from published to applicant."
      else
        application_errors = @plan_year.application_errors
        errors = @plan_year.errors.full_messages
        error_messages = application_errors.inject(""){|memo, error| "#{memo}<li>#{error[0]}: #{error[1].flatten.join(',')}</li>"} +
                         errors.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}

        flash[:error] = "Published Plan Year could not be reverted to draft. #{error_messages}".html_safe
      end
    end
    render :js => "window.location = #{employers_employer_profile_path(@employer_profile, tab: 'benefits').to_json}"
  end

  def publish
    @plan_year = @employer_profile.find_plan_year(params[:plan_year_id])

    if @plan_year.application_eligibility_warnings.present?
      respond_to do |format|
        format.js
      end
    else
      @plan_year.publish! if @plan_year.may_publish?

      if (@plan_year.published? || @plan_year.enrolling? || @plan_year.renewing_published? || @plan_year.renewing_enrolling?)
        if @plan_year.assigned_census_employees_without_owner.present?
          flash[:notice] = "Plan Year successfully published."
        else
          flash[:error] = "Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?"
        end
      else
        errors = @plan_year.application_errors.values + @plan_year.open_enrollment_date_errors.values
        flash[:error] = "Plan Year failed to publish. #{('<li>' + errors.flatten.join('</li><li>') + '</li>') if errors.try(:any?)}".html_safe
      end

      render :js => "window.location = #{employers_employer_profile_path(@employer_profile, tab: 'benefits').to_json}"
    end
  end

  def force_publish
    plan_year = @employer_profile.find_plan_year(params[:plan_year_id])
    plan_year.force_publish!
    flash[:error] = "As submitted, this application is ineligible for coverage under the #{site_short_name} exchange. If information that you provided leading to this determination is inaccurate, you have 30 days from this notice to request a review by #{site_short_name} officials."
    redirect_to employers_employer_profile_path(@employer_profile, tab: 'benefits')
  end

  def employee_costs
    @benefit_group_index = params[:benefit_group_index].to_i
    @coverage_type = params[:coverage_type]
    @location_id = params[:location_id]
    @plan_option_kind = params[:plan_option_kind]
    @plan = Plan.find(params[:reference_plan_id])
    params.merge!({ plan_year: { start_on: params[:start_on] }.merge(relationship_benefits) })

    @plan_year = ::Forms::PlanYearForm.build(@employer_profile, plan_year_params)

    @benefit_group = @plan_year.benefit_groups[0]
    @benefit_group.build_estimated_composite_rates if @plan_option_kind == 'sole_source'

    if @coverage_type == '.dental'
      @plan_year.benefit_groups[0].dental_reference_plan = @plan
      @plan_year.benefit_groups[0].dental_plan_option_kind = params[:plan_option_kind]
      if @plan_option_kind == 'single_plan'

        if params[:elected_plan_ids].present?
          @benefit_group.elected_dental_plan_ids = params[:elected_plan_ids]
        else
          benefit_group_id = @location_id.match(/^benefit-group-(.+)$/i)[1]
          plan_year = @employer_profile.plan_years.detect{|py| py.benefit_groups.where(:id => benefit_group_id).present? }
          benefit_group = plan_year.benefit_groups.detect{|bg| bg.id.to_s == benefit_group_id}
          @benefit_group.elected_dental_plan_ids = benefit_group.elected_dental_plan_ids
        end
      end
      @benefit_group.set_bounding_cost_dental_plans
    else
      @plan_year.benefit_groups[0].reference_plan = @plan
      @plan_year.benefit_groups[0].plan_option_kind = params[:plan_option_kind]
      @benefit_group.set_bounding_cost_plans
    end
    @benefit_group_costs = build_employee_costs_for_benefit_group
  end

  def generate_dental_carriers_and_plans

    @location_id = params[:location_id]
    @plan_year_id = params[:plan_year_id]
    @object_id = params[:object_id]
    @dental_carrier_names = Plan.valid_for_carrier(params.permit(:active_year)[:active_year])
    @dental_carriers_array = Organization.valid_dental_carrier_names_for_options
    respond_to do |format|
      format.js
    end
  end

  def generate_health_carriers_and_plans
    @plan_year = build_plan_year
    @benefit_group = params[:benefit_group]
    @location_id = params[:location_id]
    @panel_id = params[:panel_id]
    @start_on = params[:start_on]
    @carrier_search_level = params[:selected_carrier_level]
    @object_id = @location_id.split('-').last

    ## TODO: different if we dont have service areas enabled
    ## TODO: awfully slow
    @carrier_names = Organization.load_carriers(
                        primary_office_location: @employer_profile.organization.primary_office_location,
                        selected_carrier_level: params[:selected_carrier_level],
                        active_year: @start_on
                        )
  end

  private

  def updateable?
    authorize EmployerProfile, :updateable?
  end

  def build_employee_costs_for_benefit_group
    plan = @benefit_group.reference_plan
    plan = @benefit_group.dental_reference_plan if @coverage_type == '.dental'


    employee_costs = @plan_year.employer_profile.census_employees.active.inject({}) do |census_employees, employee|


      costs = {
        ref_plan_cost: @benefit_group.employee_cost_for_plan(employee, plan)
      }

      if !@benefit_group.single_plan_type? || @coverage_type == ".dental"
        costs.merge!({
          lowest_plan_cost: @benefit_group.employee_cost_for_plan(employee, @benefit_group.lowest_cost_plan),
          highest_plan_cost: @benefit_group.employee_cost_for_plan(employee, @benefit_group.highest_cost_plan)
          })
      end

      census_employees[employee.id] = costs
      census_employees
    end

    employee_costs.merge!({
      ref_plan_employer_cost: @benefit_group.monthly_employer_contribution_amount(plan),
      lowest_plan_employer_cost: @benefit_group.monthly_employer_contribution_amount(@benefit_group.lowest_cost_plan),
      highest_plan_employer_cost: @benefit_group.monthly_employer_contribution_amount(@benefit_group.highest_cost_plan)
      })
  end

  def find_employer
    id_params = params.permit(:id, :employer_profile_id, :active_year, :plan_year_id)
    id = id_params[:employer_profile_id] || id_params[:id]
    @employer_profile = EmployerProfile.find(id)
  end

  def generate_carriers_and_plans
    @carrier_names = Organization.valid_carrier_names(primary_office_location: @employer_profile.organization.primary_office_location)
    @carrier_names_with_sole_source = Organization.valid_carrier_names(primary_office_location: @employer_profile.organization.primary_office_location, sole_source_only: true)
    @carriers_array = Organization.valid_carrier_names_for_options(primary_office_location: @employer_profile.organization.primary_office_location)
  end

  def build_plan_year
    plan_year = PlanYear.new
    plan_year.benefit_groups.build
    plan_year.benefit_groups.first.build_relationship_benefits
    plan_year.benefit_groups.first.build_composite_tier_contributions
    plan_year.benefit_groups.first.build_dental_relationship_benefits
    ::Forms::PlanYearForm.new(plan_year)
  end

  def plan_year_params
    plan_year_params = params.require(:plan_year).permit(
      :start_on, :end_on, :fte_count, :pte_count, :msp_count,
      :open_enrollment_start_on, :open_enrollment_end_on,
      :benefit_groups_attributes => [ :id, :title, :description, :reference_plan_id, :dental_reference_plan_id, :effective_on_offset,
                                      :carrier_for_elected_plan, :carrier_for_elected_dental_plan, :metal_level_for_elected_plan,
                                      :plan_option_kind, :dental_plan_option_kind, :employer_max_amt_in_cents, :_destroy, :dental_relationship_benefits_attributes_time,
                                      :relationship_benefits_attributes => [
                                        :id, :relationship, :premium_pct, :employer_max_amt, :offered, :_destroy
                                      ],
                                      :dental_relationship_benefits_attributes => [
                                        :id, :relationship, :premium_pct, :employer_max_amt, :offered, :_destroy
                                      ],
                                      :composite_tier_contributions_attributes => [
                                        :id, :composite_rating_tier, :employer_contribution_percent, :offered
                                      ]
    ]
    )

    plan_year_params["benefit_groups_attributes"].delete_if {|k, v| v.count < 2 }
    plan_year_params
  end

  def relationship_benefits
    {
      "benefit_groups_attributes" =>
      {
        "0" => {
           "title"=>"#{TimeKeeper.date_of_record} Employer Benefits",
           "carrier_for_elected_plan"=> @plan.carrier_profile_id,
           "plan_option_kind" => @plan_option_kind,
           "reference_plan_id" => params[:reference_plan_id],
           "dental_relationship_benefits_attributes" => params[:dental_relation_benefits]
        }.merge(composite_or_relation_benefits)
      }
    }
  end

  def composite_or_relation_benefits
    if @plan_option_kind.nil?
      return { "relationship_benefits_attributes" => params[:relation_benefits] }
    elsif @plan_option_kind == 'sole_source'
      return { "composite_tier_contributions_attributes" => params[:relation_benefits] }
    else
      return { "relationship_benefits_attributes" => params[:relation_benefits] }
    end
  end

  def no_products_message(plan_year)
    "Unable to continue application, as this employer is either ineligible to enroll on the #{Settings.site.long_name}, or no products are available for a benefit plan year starting #{plan_year.start_on}"
  end

end
