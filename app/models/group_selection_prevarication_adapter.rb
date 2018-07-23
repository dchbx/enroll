class GroupSelectionPrevaricationAdapter
	attr_accessor :person
	attr_accessor :family
	attr_accessor :coverage_household
	attr_accessor :previous_hbx_enrollment
	attr_accessor :change_plan
	attr_accessor :coverage_kind
	attr_accessor :enrollment_kind
	attr_accessor :shop_for_plans
	attr_accessor :optional_effective_on

	include ActiveModel::Model

	def self.initialize_for_common_vars(params)
		person_id = params.require(:person_id)
		person = Person.find(person_id)
		family = person.primary_family
		coverage_household = family.active_household.immediate_family_coverage_household
		change_plan = params[:change_plan].present? ? params[:change_plan] : ''
		coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
		enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
		shop_for_plans = params[:shop_for_plans].present? ? params[:shop_for_plans] : ''
		optional_effective_on = params[:effective_on_option_selected].present? ? Date.strptime(params[:effective_on_option_selected], '%m/%d/%Y') : nil
		record = self.new(
			person: person,
			family: family,
			coverage_household: coverage_household,
			change_plan: change_plan,
			coverage_kind: coverage_kind,
			enrollment_kind: enrollment_kind,
			shop_for_plans: shop_for_plans,
			optional_effective_on: optional_effective_on
		)
		if params[:hbx_enrollment_id].present?
			record.previous_hbx_enrollment = ::HbxEnrollment.find(params[:hbx_enrollment_id])
		end
		record.check_shopping_roles(params)
		record
	end

	def check_shopping_roles(params)
		if params[:employee_role_id].present?
			emp_role_id = params.require(:employee_role_id)
			@employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
		elsif params[:resident_role_id].present?
			@resident_role = @person.resident_role
		end
	end

	def can_ivl_shop?(params)
		(select_market(params) == 'individual') || (@person.try(:has_active_employee_role?) && @person.try(:has_active_consumer_role?)) || @person.resident_role?
	end

	def possible_resident_person
		@person.resident_role? ? @person : nil
	end

	def if_changing_ivl?(params)
		can_ivl_shop?(params) && params[:hbx_enrollment_id].present?
	end

	def if_employee_role_unset_but_can_be_derived(e_role_value)
    return if e_role_value.present?
		if @person.has_active_employee_role?
			@person.active_employee_roles.first
		end
	end

  def if_previous_enrollment_was_special_enrollment
    return nil unless @previous_hbx_enrollment.present?
    if @previous_hbx_enrollment.is_special_enrollment?
      yield
    end
  end

	def possible_employee_role
		if @employee_role.nil? && @person.has_active_employee_role?
			@person.active_employee_roles.first
		else
			@employee_role
		end
	end

	def if_employee_role
		return nil unless possible_employee_role.present?
		yield possible_employee_role
	end

	def if_resident_role
		return nil unless @resident_role.present?
		yield @resident_role
	end

	def if_consumer_role
		return nil if @employee_role.present? || @resident_role.present?
		yield person.consumer_role
	end

  def keep_existing_plan?(params)
    params[:commit] == "Keep existing plan"
  end

	def benefit_group_assignment_by_plan_year(employee_role, benefit_group, change_plan)
		benefit_group.plan_year.is_renewing? ?
			employee_role.census_employee.renewal_benefit_group_assignment : (benefit_group.plan_year.aasm_state == "expired" && (change_plan == 'change_by_qle' or enrollment_kind == 'sep')) ? employee_role.census_employee.benefit_group_assignments.where(benefit_group_id: benefit_group.id).first : employee_role.census_employee.active_benefit_group_assignment
	end

	def set_mc_variables
		if @previous_hbx_enrollment.present? && @change_plan == "change_plan"
			m_kind = @previous_hbx_enrollment.kind == "employer_sponsored" ? "shop" : "individual"
			yield m_kind, @previous_hbx_enrollment.coverage_kind
		end
	end

	def disable_market_kinds(params)
		if (@change_plan == 'change_by_qle' || @enrollment_kind == 'sep')
			d_market_kind = (select_market(params) == "shop") ? "individual" : "shop"
			yield d_market_kind
		end
	end

	def ivl_benefit
		correct_effective_on = calculate_ivl_effective_on
		HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.select{|bcp| bcp.contains?(correct_effective_on)}.first.benefit_packages.select{|bp|  bp[:title] == "individual_health_benefits_#{correct_effective_on.year}"}.first
	end

	def calculate_ivl_effective_on
		calculate_effective_on(market_kind: 'individual', employee_role: nil, benefit_group: nil)
	end

	def calculate_new_effective_on(params)
		benefit_group = select_benefit_group(params)
		calculate_effective_on(market_kind: select_market(params), employee_role: possible_employee_role, benefit_group: benefit_group)
	end

	def calculate_effective_on(market_kind:, employee_role:, benefit_group:)
		HbxEnrollment.calculate_effective_on_from(
			market_kind: market_kind,
			qle: (@change_plan == 'change_by_qle' or @enrollment_kind == 'sep'),
			family: @family,
			employee_role: employee_role,
			benefit_group: benefit_group,
			benefit_sponsorship: HbxProfile.current_hbx.try(:benefit_sponsorship))
	end

	def if_qle_with_date_option_selected(params)
		if params[:effective_on_option_selected].present?
			yield Date.strptime(params[:effective_on_option_selected], '%m/%d/%Y')
		end
	end

  def if_change_plan_selected(params)
    if @change_plan == 'change_plan' && @previous_hbx_enrollment.present?
      yield @previous_hbx_enrollment.effective_on
    end
  end

	def if_should_generate_coverage_family_members_for_cobra(params)
		if (select_market(params) == 'shop') && !(@change_plan == 'change_by_qle' || @enrollment_kind == 'sep') && possible_employee_role.present? && possible_employee_role.is_cobra_status?
			hbx_enrollment = @family.active_household.hbx_enrollments.shop_market.enrolled_and_renewing.effective_desc.detect { |hbx| hbx.may_terminate_coverage? }
			if hbx_enrollment.present?
				yield(hbx_enrollment.hbx_enrollment_members.map(&:family_member))
			end
		end
	end

	def if_hbx_enrollment_unset_and_sep_or_qle_change_and_can_derive_previous_shop_enrollment(params, enrollment, new_effective_date)
		if (select_market(params) == 'shop') && (@change_plan == 'change_by_qle') && enrollment.blank?
      
			prev_enrollment = find_previous_enrollment_for(params, new_effective_date)
      if prev_enrollment
			  yield prev_enrollment
      else
        yield nil, nil
      end
		end
	end

  def can_waive?(hbx_enrollment, params)
    if hbx_enrollment.present?
      hbx_enrollment.is_shop?
    else
      (select_market(params) == "shop")
    end
  end

  def find_previous_enrollment_for(params, new_effective_date)
    @family.households.flat_map(&:hbx_enrollments).detect do |other_enrollment|
      (other_enrollment.employee_role_id == possible_employee_role.id) &&
        other_enrollment.active_during?(new_effective_date) &&
        (other_enrollment.coverage_kind == @coverage_kind)
    end
  end

	def is_qle?
		(@change_plan == 'change_by_qle' or @enrollment_kind == 'sep')
	end

	def select_benefit_group(params)
    if @change_plan.present? && @previous_hbx_enrollment.present?
      @previous_hbx_enrollment.sponsored_benefit_package 
    else
      if (select_market(params) == "shop") && possible_employee_role.present?
        possible_employee_role.benefit_package(qle: is_qle?)
      end
    end
  end

	def selected_enrollment(family, employee_role)
		employer_profile = employee_role.employer_profile
		py = employer_profile.plan_years.detect { |py| is_covered_plan_year?(py, family.current_sep.effective_on)} || employer_profile.published_plan_year
		enrollments = family.active_household.hbx_enrollments
		if py.present? && py.is_renewing?
			renewal_enrollment(enrollments, employee_role)
		else
			active_enrollment(enrollments, employee_role)
		end
	end

	def renewal_enrollment(enrollments, employee_role)
		enrollments.where({
			:"benefit_group_id" => employee_role.census_employee.renewal_published_benefit_group.try(:id),
			:"aasm_state".in => HbxEnrollment::RENEWAL_STATUSES
		}).first
	end

	def active_enrollment(enrollments, employee_role)
		enrollments.where({
			:"benefit_group_id" => employee_role.census_employee.active_benefit_group.try(:id),
			:"aasm_state".in => HbxEnrollment::ENROLLED_STATUSES
		}).first
	end

	def select_market(params)
		return params[:market_kind] if params[:market_kind].present?
		if params[:qle_id].present? && (!person.has_active_resident_role?)
			qle = QualifyingLifeEventKind.find(params[:qle_id])
			return qle.market_kind
		end
		if person.has_active_employee_role?
			'shop'
		elsif person.has_active_consumer_role? && !person.has_active_resident_role?
			'individual'
		elsif person.has_active_resident_role?
			'coverall'
		else
			nil
		end
	end

	def create_action_market_kind(params)
		params[:market_kind].present? ? params[:market_kind] : 'shop'
	end

  # SHOP enrollment creation adapters
  def build_shop_change_enrollment(
    controller_employee_role,
    controller_change_plan,
    family_member_ids
  )
    e_builder = ::EnrollmentShopping::EnrollmentBuilder.new(coverage_household, controller_employee_role, coverage_kind)
    e_builder.build_change_enrollment(previous_enrollment: previous_hbx_enrollment, is_qle: is_qle?, optional_effective_on: optional_effective_on, family_member_ids: family_member_ids)
  end

  def build_new_shop_enrollment(
    controller_employee_role,
    family_member_ids
  )
    build_new_shop_enrollment_for_family_members(
      controller_employee_role,
      family_member_ids)
  end

  def build_new_shop_waiver_enrollent(controller_employee_role, params)
    e_builder = ::EnrollmentShopping::EnrollmentBuilder.new(coverage_household, controller_employee_role, coverage_kind)
    e_builder.build_new_waiver_enrollment(is_qle: is_qle?, optional_effective_on: optional_effective_on, waiver_reason: get_waiver_reason(params))
  end

  def build_change_shop_waiver_enrollment(
    controller_employee_role,
    controller_change_plan,
    params
  )
    e_builder = ::EnrollmentShopping::EnrollmentBuilder.new(coverage_household, controller_employee_role, coverage_kind)
    e_builder.build_change_waiver_enrollment(previous_enrollment: previous_hbx_enrollment, is_qle: is_qle?, optional_effective_on: optional_effective_on, waiver_reason: get_waiver_reason(params))
  end

  def is_waiving?(params)
    !params[:is_waiving].blank?
  end

  def get_waiver_reason(params)
    params[:waiver_reason]
  end

  def can_shop_shop?(person)
    person.present? && person.has_employer_benefits?
  end

  def can_shop_individual?(person)
    false
  end

  def can_shop_resident?(person)
    false
  end

  def can_shop_both_markets?(person)
    false
  end

  def is_eligible_for_dental?(employee_role, is_change_plan, enrollment)
    false
  end

  def is_dental_offered?(employee_role)
    false
  end

	def shop_health_and_dental_attributes(family_member, employee_role, coverage_start)
		benefit_group = get_benefit_group(@benefit_group, employee_role, @qle)

    # Here we need to use the complex method to determine if this member is eligible to enroll
    eligibility_checker = shop_benefit_eligibilty_checker_for(benefit_group, :health)
    [eligibility_checker.can_cover?(family_member, coverage_start), false]
	end

	def class_for_ineligible_row(family_member, is_ivl_coverage, coverage_start)
		class_names = @person.active_employee_roles.inject([]) do |class_names, employee_role|
			is_health_coverage, is_dental_coverage = shop_health_and_dental_attributes(family_member, employee_role, coverage_start)

			if !is_health_coverage && !is_health_coverage.nil?
				class_names << "ineligible_health_row_#{employee_role.id}"
			end

			if !is_dental_coverage && !is_dental_coverage.nil?
				class_names << "ineligible_dental_row_#{employee_role.id}"
			end
			class_names
		end

		class_names << "ineligible_ivl_row" if (!is_ivl_coverage.nil? && !is_ivl_coverage)
		class_names << "is_primary" if family_member.is_primary_applicant?

		class_names.to_sentence.gsub("and", '').gsub(",", "")
	end

	def get_benefit_group(benefit_group, employee_role, qle)
		if benefit_group.present? && (employee_role.employer_profile == benefit_group.sponsor_profile )
			benefit_group
		else
			select_benefit_group_from_qle_and_employee_role(qle, possible_employee_role)
		end
	end

	def select_benefit_group_from_qle_and_employee_role(qle, employee_role)
	  employee_role.benefit_package(qle: qle)
	end

  # Assignment will never be nil unless you're setting incorrect sponsored_benefit_package on enrollment
  def assign_enrollment_to_benefit_package_assignment(employee_role, enrollment)
    assignment = employee_role.census_employee.benefit_group_assignment_by_package(enrollment.sponsored_benefit_package_id)
    assignment.update(hbx_enrollment_id: enrollment.id)
    enrollment.update(benefit_group_assignment_id: assignment.id)
  end

	protected

  def build_new_shop_enrollment_for_family_members(
    controller_employee_role,
    family_member_ids
  )
    e_builder = ::EnrollmentShopping::EnrollmentBuilder.new(coverage_household, controller_employee_role, coverage_kind)
    e_builder.build_new_enrollment(family_member_ids: family_member_ids, is_qle: is_qle?, optional_effective_on: optional_effective_on)
	end

	def shop_health_and_dental_relationship_benefits(employee_role, benefit_group)
		health_offered_relationship_benefits = health_relationship_benefits(benefit_group)
    dental_offered_relationship_benefits = nil

		if is_eligible_for_dental?(employee_role, @change_plan, @hbx_enrollment)
			dental_offered_relationship_benefits = dental_relationship_benefits(benefit_group)
		end

		return health_offered_relationship_benefits, dental_offered_relationship_benefits
	end

	def health_relationship_benefits(benefit_group)
		return unless benefit_group.present?

		benefit_group.sole_source? ? composite_benefits(benefit_group) : traditional_benefits(benefit_group)
	end

	def composite_benefits(benefit_group)
		benefit_group.composite_tier_contributions.select(&:offered).map(&:composite_rating_tier)
	end

	def traditional_benefits(benefit_group)
		benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
	end

  def shop_eligibility_checkers
    @shop_eligibility_checkers ||= Hash.new
  end

	def shop_benefit_eligibilty_checker_for(benefit_package, coverage_kind)
		shop_eligibility_checkers[coverage_kind] ||= GroupSelectionEligibilityChecker.new(benefit_package, coverage_kind)
	end
end
