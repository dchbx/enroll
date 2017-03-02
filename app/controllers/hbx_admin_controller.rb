class HbxAdminController < ApplicationController
  $months_array = Date::ABBR_MONTHNAMES.compact

  def edit_aptc_csr
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?
    @person = Person.find(params[:person_id])
    @family = Family.find(params[:family_id])
    @current_year = (params[:year] || Admin::Aptc.years_with_tax_household(@family).sort.last).to_i # Use the selected year or the most recent year for which there is a TH.
    @hbxs = @family.active_household.hbx_enrollments.enrolled_and_renewing.by_year(@current_year).by_coverage_kind("health")
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
    year = params[:person][:current_year].to_i
    @person = Person.find(params[:person][:person_id]) if params[:person].present? && params[:person][:person_id].present?
    @family = Family.find(params[:person][:family_id]) if params[:person].present? && params[:person][:family_id].present?
    @hbxs = @family.active_household.hbx_enrollments.enrolled_and_renewing.by_year(year).by_coverage_kind("health")
    @household_info = Admin::Aptc.build_household_level_aptc_csr_data(year, @family, @hbxs, params[:max_aptc].to_f, params[:csr_percentage])
    if @family.present? #&& TimeKeeper.date_of_record.year == year
      @eligibility_redetermination_result = Admin::Aptc.redetermine_eligibility_with_updated_values(@family, params, @hbxs, year)
      @enrollment_update_result = Admin::Aptc.update_aptc_applied_for_enrollments(@family, params, year)
    end
    respond_to do |format|
      format.js { render "update_aptc_csr", person: @person}
    end
  end

  # For AJAX Calculations.
  def calculate_aptc_csr
    raise NotAuthorizedError if !current_user.has_hbx_staff_role?
    @current_year = (params[:year] || Admin::Aptc.years_with_tax_household(@family).sort.last).to_i
    @person = Person.find(params[:person_id])
    @family = Family.find(params[:family_id])
    @hbxs = @family.active_household.hbx_enrollments.enrolled_and_renewing.by_year(@current_year).by_coverage_kind("health")
    @aptc_errors = Admin::Aptc.build_error_messages(params[:max_aptc], params[:csr_percentage], params[:applied_aptcs_array], @current_year, @hbxs)
    @household_info = Admin::Aptc.build_household_level_aptc_csr_data(@current_year, @family, @hbxs, params[:max_aptc].to_f, params[:csr_percentage], params[:applied_aptcs_array])
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

end
