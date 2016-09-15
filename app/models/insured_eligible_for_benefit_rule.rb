class InsuredEligibleForBenefitRule

  # Insured role can be: EmployeeRole, ConsumerRole, ResidentRole


  # ACA_ELIGIBLE_CITIZEN_STATUS_KINDS = %W(
  #     us_citizen
  #     naturalized_citizen
  #     indian_tribe_member
  #     alien_lawfully_present
  #     lawful_permanent_resident
  # )

  def initialize(role, benefit_package, coverage_kind='health')
    @role = role
    @benefit_package = benefit_package
    @coverage_kind = coverage_kind
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
    if @role.class.name == "ConsumerRole"
      @errors = []
      status = @benefit_package.benefit_eligibility_element_group.class.fields.keys.reject{|k| k == "_id"}.reduce(true) do |eligible, element|
        if self.public_send("is_#{element}_satisfied?")
          true && eligible
        else
          @errors << ["eligibility failed on #{element}"]
          false
        end
      end
      status = false if is_age_range_satisfied_for_catastrophic? == false
      return status, @errors
    end
    [false]
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
    tax_household = @role.latest_active_tax_household_with_year(@benefit_package.effective_year)
    return true if tax_household.blank?

    cost_sharing = @benefit_package.cost_sharing
    csr_kind = tax_household.current_csr_eligibility_kind
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
    age = age_on_next_effective_date(@role.dob)
    relation_ship_with_primary_applicant == 'child' && age > 26 ? false : true
  end

  def is_benefit_categories_satisfied?
    @benefit_package.benefit_categories.include? @coverage_kind
  end

  def is_citizenship_status_satisfied?
    @role.citizen_status == "not_lawfully_present_in_us" ? false : true
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
      person.families.last.family_members.active.each do |family_member|
        if age_on_next_effective_date(family_member.dob) >= 19 && family_member.is_dc_resident?
          return true
        end
      end
    end
    return false
  end

  def is_incarceration_status_satisfied?
    return true if @benefit_package.incarceration_status.include?("any")
    @benefit_package.incarceration_status.include?("unincarcerated") && !@role.is_incarcerated?
  end

  def is_age_range_satisfied?
    return true if @benefit_package.age_range == (0..0)

    age = age_on_next_effective_date(@role.dob)
    @benefit_package.age_range.cover?(age)
  end

  def is_lawful_presence_status_satisfied?
    is_verification_satisfied? || is_person_vlp_verified?
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
    @role.person.families.last.family_members.select {|s| s.is_primary_applicant}.first || nil
  end

  def relation_ship_with_primary_applicant
    primary_applicant.person.person_relationships.select {|r|r.relative_id.to_s == @role.person.id.to_s}.first.try(:kind) || nil
  # @role.person.person_relationships.select {|r| r.person.id.to_s == primary_applicant.person_id.to_s }.first.try(:kind) || nil
  end

end
