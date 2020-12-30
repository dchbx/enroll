class HbxAdminController < ApplicationController
  $months_array = Date::ABBR_MONTHNAMES.compact

  before_action :find_values, only: [:update_aptc_csr, :calculate_aptc_csr, :edit_aptc_csr]
  before_action :validate_aptc, only: [:update_aptc_csr, :calculate_aptc_csr]

  def edit_aptc_csr
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?

    @slcsp_value = Admin::Aptc.calculate_slcsp_value(@current_year, @family)
    @household_members = Admin::Aptc.build_household_members(@current_year, @family)
    @household_info = Admin::Aptc.build_household_level_aptc_csr_data(@current_year, @family, @hbxs)
    @enrollments_info = Admin::Aptc.build_enrollments_data(@current_year, @family, @hbxs) if @hbxs.present?
    @current_aptc_applied_hash =  Admin::Aptc.build_current_aptc_applied_hash(@hbxs)
    @plan_premium_for_enrollments = Admin::Aptc.build_plan_premium_hash_for_enrollments(@hbxs)
    @active_tax_household_for_current_year = @family.active_household.latest_active_tax_household_with_year(@current_year)
    @max_aptc = @active_tax_household_for_current_year.try(:latest_eligibility_determination).try(:max_aptc) || 0
    @csr_percent_as_integer = @active_tax_household_for_current_year.try(:latest_eligibility_determination).try(:csr_percent_as_integer) || 0
    @year_options = Admin::Aptc::years_with_tax_household(@family)
    respond_to do |format|
      format.js { render (@hbxs.blank? ? "edit_aptc_csr_no_enrollment" : "edit_aptc_csr_active_enrollment")}
    end
  end

  def update_aptc_csr
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?

    if @aptc_errors.blank?
      if @family.present? #&& TimeKeeper.date_of_record.year == year
        @eligibility_redetermination_result = Admin::Aptc.redetermine_eligibility_with_updated_values(@family, params, @hbxs, @current_year)
        @enrollment_update_result = Admin::Aptc.update_aptc_applied_for_enrollments(@family, params, @current_year)
      end
      respond_to do |format|
        format.js {render "update_aptc_csr", person: @person}
      end
    else
      respond_to do |format|
        format.js { render "household_header"}
      end
    end
  end

  # For AJAX Calculations.
  def calculate_aptc_csr
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?

    @enrollments_info = Admin::Aptc.build_enrollments_data(@current_year, @family, @hbxs, params[:applied_aptcs_array], params[:max_aptc].to_f, params[:csr_percentage].to_i, params[:memeber_ids])
    @slcsp_value = Admin::Aptc.calculate_slcsp_value(@current_year, @family)
    @household_members = Admin::Aptc.build_household_members(@current_year, @family, params[:max_aptc].to_f)
    @current_aptc_applied_hash =  Admin::Aptc.build_current_aptc_applied_hash(@hbxs, params[:applied_aptcs_array])
    @plan_premium_for_enrollments = Admin::Aptc.build_plan_premium_hash_for_enrollments(@hbxs)
    @active_tax_household_for_current_year = @family.active_household.latest_active_tax_household_with_year(@current_year)
    @max_aptc = ( params[:max_aptc]=="NaN" ? params[:max_aptc] : '%.2f' % params[:max_aptc] ) || @family.active_household.tax_households.tax_household_with_year(@current_year).last.try(:latest_eligibility_determination).try(:max_aptc) || 0
    @csr_percent_as_integer = params[:csr_percentage] || @family.active_household.tax_households.tax_household_with_year(@current_year).last.try(:latest_eligibility_determination).try(:csr_percent_as_integer) || 0
    @year_options = Admin::Aptc::years_with_tax_household(@family)
    respond_to do |format|
      format.js { render (@hbxs.blank? ? "edit_aptc_csr_no_enrollment" : "edit_aptc_csr_active_enrollment")} if @aptc_errors.blank?
      format.js { render "household_header"} if @aptc_errors.present?
    end
  end

  private

  def find_values
    attr = params[:person] || params
    @person = Person.find(attr[:person_id])
    @family = Family.find(attr[:family_id])
    @current_year = (attr[:current_year] || attr[:year] || Admin::Aptc.years_with_tax_household(@family).sort.last).to_i
    @hbxs = @family.active_household.hbx_enrollments.enrolled_and_renewing.by_year(@current_year).by_coverage_kind('health')
    @household_info = Admin::Aptc.build_household_level_aptc_csr_data(@current_year, @family, @hbxs, attr[:max_aptc].to_f, attr[:csr_percentage])
  end

  def validate_aptc
    @aptc_errors = Admin::Aptc.build_error_messages(params[:max_aptc], params[:csr_percentage], params[:applied_aptcs_array], @current_year, @hbxs)
  end
end