class InsuredEligibleForBenefitRule

  # Insured role can be: EmployeeRole, ConsumerRole, ResidentRole


  # ACA_ELIGIBLE_CITIZEN_STATUS_KINDS = %W(
  #     us_citizen
  #     naturalized_citizen
  #     indian_tribe_member
  #     alien_lawfully_present
  #     lawful_permanent_resident
  # )

  def initialize(role, benefit_package, options = {})
    @role = role
    @family = options[:family] || @role.person.families.first
    @benefit_package = benefit_package
    @coverage_kind = options[:coverage_kind].present? ? options[:coverage_kind] : 'health'
    @new_effective_on = options[:new_effective_on]
    @market_kind = options[:market_kind]
  end

  def setup
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bp| bp.start_on.year == 2015 }
    ivl_health_benefits_2015 = bc_period.benefit_packages.detect { |bp| bp.title == "individual_health_benefits_2015" }

    person = Person.where(last_name: "Murray").entries.first
    if person.consumer_role.nil?
      consumer_role = person.build_consumer_role(is_applicant: true)
      consumer_role.save!
      consumer_role
    else
      consumer_role = person.consumer_role
    end

    # rule = InsuredEligibleForBenefitRule.new(consumer_role, ivl_health_benefits_2015)
    # rule.satisfied?
  end

  def satisfied?
    if @role.class.name == "ConsumerRole" || @role.class.name == "ResidentRole"
      @errors = []
      status = @benefit_package.benefit_eligibility_element_group.class.fields.keys.reject{|k| k == "_id"}.reduce(true) do |eligible, element|
        if @market_kind == "shop" && !("#{element}" == "active_consumer")
          if self.public_send("is_#{element}_satisfied?")
            true && eligible
          end
        elsif self.public_send("is_#{element}_satisfied?")
          true && eligible
        else
          if "#{element}" == "active_consumer"
             @errors << ["eligibility failed on market kind"]
          else
            @errors << ["eligibility failed on #{element}"]
          end
          false
        end
      end
      status = false if is_age_range_satisfied_for_catastrophic? == false
      status = set_status_and_error_if_not_applying_coverage if @role.class.name == "ConsumerRole" && is_applying_coverage_status_satisfied? == false
      return status, @errors
    end
    [false]
  end

  def set_status_and_error_if_not_applying_coverage
    status = false
    @errors = ["Did not apply for coverage."]
    return status
  end

  def is_applying_coverage_status_satisfied?
    @role.is_applying_coverage?
  end

  def is_age_range_satisfied_for_catastrophic?
     if @benefit_package.age_range == (0..30)
       benefit_end_on = @benefit_package.benefit_coverage_period.end_on
       age = age_on_benefit_end_on(@role.dob, benefit_end_on)
       @benefit_package.age_range.cover?(age)
     else
       return true
     end
  end

  def is_cost_sharing_satisfied?
    tax_households = @role.latest_active_tax_households_with_year(@benefit_package.effective_year, @family)
    return true if tax_households.blank?

    #TODO Multi TaxHouseholds pick the right tax_household if tax_households count more than 1
    cost_sharing = @benefit_package.cost_sharing
    csr_kind = tax_households.first.current_csr_eligibility_kind
    return true if csr_kind.blank? || cost_sharing.blank?
    csr_kind == cost_sharing
  end

  def is_market_places_satisfied?
    true
  end

  def is_enrollment_periods_satisfied?
    true
  end

  def is_family_relationships_satisfied?
    return true unless relation_ship_with_primary_applicant == 'child'
    is_child_age_satisfied?
  end

  def is_child_age_satisfied?
    unless @new_effective_on.nil?
      relation_ship_with_primary_applicant == 'child' && @new_effective_on.kind_of?(Date) && @new_effective_on < @role.dob+26.years ? true : false
    else
      age = age_on_next_effective_date(@role.dob)
      relation_ship_with_primary_applicant == 'child' && age > 26 ? false : true
    end
  end

  def is_benefit_categories_satisfied?
    @benefit_package.benefit_categories.include? @coverage_kind
  end

  def is_citizenship_status_satisfied?
    return true if @role.is_a?(ResidentRole)
    return false if @role.citizen_status.blank?
    !ConsumerRole::INELIGIBLE_CITIZEN_VERIFICATION.include? @role.citizen_status
  end

  def is_ethnicity_satisfied?
    true
  end

  def is_residency_status_satisfied?
    return true if @benefit_package.residency_status.include?("any")

    if @benefit_package.residency_status.include?("state_resident") && @role.present?
      person = @role.person
      return true if person.is_dc_resident?

      #TODO person can have more than one families
      @family.family_members.active.each do |family_member|
        if age_on_next_effective_date(family_member.dob) >= 19 && family_member.is_dc_resident?
          return true
        end
      end
    end
    return false
  end

  def is_incarceration_status_satisfied?
    return true if @benefit_package.incarceration_status.include?("any")
    @benefit_package.incarceration_status.include?("unincarcerated") && (@role.is_incarcerated == false)
  end

  def is_age_range_satisfied?
    return true if @benefit_package.age_range == (0..0)
    age = age_on_next_effective_date(@role.dob)
    @benefit_package.age_range.cover?(age)
  end

  def is_lawful_presence_status_satisfied?
    is_verification_satisfied? || is_person_vlp_verified?
  end

  def is_active_individual_role_satisfied?
    return (@role.person.is_resident_role_active? || @role.person.is_consumer_role_active?) if @market_kind == "coverall"
    return @role.person.is_consumer_role_active? if @market_kind == "individual"
  end

  def determination_results
    @errors
  end

  # def fails_market_places?
  #   if passes
  #     false
  #   else
  #     reason
  #   end
  # end

  def age_on_benefit_end_on(dob, end_on=TimeKeeper.date_of_record)
    # calculate method depend on 6710
    end_on.year - dob.year - ((end_on.month > dob.month || (end_on.month == dob.month && end_on.day >= dob.day)) ? 0 : 1)
  end

  def age_on_next_effective_date(dob)
    today = TimeKeeper.date_of_record
    today.day <= 15 ? age_on = today.end_of_month + 1.day : age_on = (today + 1.month).end_of_month + 1.day
    age_on.year - dob.year - ((age_on.month > dob.month || (age_on.month == dob.month && age_on.day >= dob.day)) ? 0 : 1)
  end

  private

  def is_verification_satisfied?
    return true if Settings.aca.individual_market.verification_outstanding_window.days == 0
    !(@role.lawful_presence_determination.aasm_state == "verification_outstanding" && !@role.lawful_presence_determination.latest_denial_date.try(:+, Settings.aca.individual_market.verification_outstanding_window.days).try(:>, TimeKeeper.date_of_record))
  end

  def is_person_vlp_verified?
    @role.aasm_state == "fully_verified" ? true : false
  end

  def primary_applicant
    @family.family_members.select {|s| s.is_primary_applicant}.first || nil
  end

  def relation_ship_with_primary_applicant
    primary_applicant.person.person_relationships.select {|r|r.relative_id.to_s == @role.person.id.to_s}.first.try(:kind) || nil
  # @role.person.person_relationships.select {|r| r.person.id.to_s == primary_applicant.person_id.to_s }.first.try(:kind) || nil
  end

end
