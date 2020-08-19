class Household
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include HasFamilyMembers

  ImmediateFamily = %w{self spouse life_partner child ward foster_child adopted_child stepson_or_stepdaughter stepchild domestic_partner}

  embedded_in :family

  # field :e_pdc_id, type: String  # Eligibility system PDC foreign key

  # embedded belongs_to :irs_group association
  field :irs_group_id, type: BSON::ObjectId
  field :effective_starting_on, type: Date
  field :effective_ending_on, type: Date
  field :submitted_at, type: DateTime
  field :is_active, type: Boolean, default: true

  embeds_many :hbx_enrollments
  embeds_many :tax_households
  embeds_many :coverage_households, cascade_callbacks: true

  accepts_nested_attributes_for :hbx_enrollments, :tax_households, :coverage_households

  before_validation :set_effective_starting_on
  before_validation :set_effective_ending_on #, :if => lambda {|household| household.effective_ending_on.blank? } # set_effective_starting_on should be done before this
  before_validation :reset_is_active_for_previous
  before_validation :set_submitted_at #, :if => lambda {|household| household.submitted_at.blank? }

  validates :effective_starting_on, presence: true
  #validate :effective_ending_on_gt_effective_starting_on

  # after_build :build_irs_group

  def active_hbx_enrollments
    actives = hbx_enrollments.collect() do |list, enrollment|
      if enrollment.plan.present? &&
         (enrollment.plan.active_year >= TimeKeeper.date_of_record.year) &&
         (HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state))

        list << enrollment
      end
      list
    end
    actives.sort! { |a,b| a.submitted_at <=> b.submitted_at }
  end

  def renewing_hbx_enrollments
    active_hbx_enrollments.reject { |en| !HbxEnrollment::RENEWAL_STATUSES.include?(enrollment.aasm_state) }
  end

  def renewing_individual_market_hbx_enrollments
    renewing_hbx_enrollments.reject { |en| en.enrollment_kind != 'individual' }
  end

  def add_household_coverage_member(family_member)
    if Family::IMMEDIATE_FAMILY.include?(family_member.primary_relationship)
      immediate_family_coverage_household.add_coverage_household_member(family_member)
      extended_family_coverage_household.remove_family_member(family_member)
    else
      immediate_family_coverage_household.remove_family_member(family_member)
      extended_family_coverage_household.add_coverage_household_member(family_member)
    end
  end

  def immediate_family_coverage_household
    ch = coverage_households.detect { |hh| hh.is_immediate_family? }
    ch ||= coverage_households.build(is_immediate_family: true)
  end

  def extended_family_coverage_household
    ch = coverage_households.detect { |hh| !hh.is_immediate_family? }
    ch ||= coverage_households.build(is_immediate_family: false)
  end

  # def determination_split_coverage_household
  #   hh = coverage_household.find_or_initialize_by(is_determination_split_household: true)
  #   hh.submitted_at ||= DateTime.current
  #   hh
  # end

  def build_or_update_tax_households_and_eligibility_determinations(verified_family, primary_person, active_verified_household, new_dependents)
    verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.id == verified_family.primary_family_member_id }
    verified_tax_households = active_verified_household.tax_households.select{|th| th.id == th.primary_applicant_id && th.primary_applicant_id == verified_primary_family_member.id.split('#').last }

    if tax_households.present?
      latest_tax_households = tax_households.where(effective_ending_on: nil)
      latest_tax_households.each do |thh|
        thh.update_attributes(effective_ending_on: verified_tax_households.first.start_date)
      end
    end

    verified_tax_households.each do |verified_tax_household|
      if verified_tax_household.present? && verified_tax_household.eligibility_determinations.present?

        th = tax_households.build(
          allocated_aptc: verified_tax_household.allocated_aptcs.first.total_amount,
          effective_starting_on: verified_tax_household.start_date,
          is_eligibility_determined: true,
          submitted_at: verified_tax_household.submitted_at
        )

        new_dependents << [primary_person, "self", [verified_primary_family_member.id]]

        verified_tax_household.tax_household_members.each do |tax_household_member|
          family_member = nil
          new_dependents.each do |dependent|
            if dependent[2][0] == tax_household_member.id
              family_member = family.family_members.select{|fm| fm if fm.person.id.to_s == dependent[0].id.to_s}.first
            end
          end

          th.tax_household_members.build(
            family_member: family_member,
            applicant_id: family_member.id,
            is_subscriber: true,
            is_ia_eligible: tax_household_member.is_insurance_assistance_eligible ? tax_household_member.is_insurance_assistance_eligible : false,
            is_medicaid_chip_eligible: tax_household_member.is_medicaid_chip_eligible,
            is_without_assistance: tax_household_member.is_without_assistance
          )
        end

        benchmark_plan_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp
        latest_eligibility_determination = verified_tax_household.eligibility_determinations.max_by(&:determination_date)
        th.eligibility_determinations.build(
          e_pdc_id: latest_eligibility_determination.id,
          benchmark_plan_id: benchmark_plan_id,
          max_aptc: latest_eligibility_determination.maximum_aptc,
          csr_percent_as_integer: latest_eligibility_determination.csr_percent,
          determined_on: latest_eligibility_determination.determination_date,
          source: "Curam"
        )
        th.save!
      end
    end
  end

  def build_or_update_tax_households_and_applicants_and_eligibility_determinations(verified_family, primary_person, active_verified_household, application_in_context)
    verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
    verified_tax_households = active_verified_household.tax_households.select{|th| th.primary_applicant_id == verified_family.primary_family_member_id}
    if verified_tax_households.present?# && !verified_tax_households.map(&:eligibility_determinations).map(&:present?).include?(false)
      if latest_active_tax_households.present?
        latest_active_tax_households.each do |latest_tax_household|
          latest_tax_household.update_attributes(effective_ending_on: verified_tax_households.first.start_date)
        end
      end

      tax_households_hbx_assigned_ids = []
      tax_households.each { |th| tax_households_hbx_assigned_ids << th.hbx_assigned_id.to_s}
      benchmark_plan_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp
      verified_tax_households.each do |vthh|
        #If taxhousehold exists in our DB
        if tax_households_hbx_assigned_ids.include?(vthh.hbx_assigned_id)
          tax_household = tax_households.where(hbx_assigned_id: vthh.hbx_assigned_id).first
          #Update required attributes for that particular TaxHouseHold
          tax_household.update_attributes(effective_starting_on: vthh.start_date, is_eligibility_determined: true)
          #Applicant/TaxHouseholdMember block start
          applicants_persons_hbx_ids = []
          application_in_context.applicants.each { |appl| applicants_persons_hbx_ids << appl.person.hbx_id.to_s}
          vthh.tax_household_members.each do |thhm|
            #If applicant exisits in our db.
            if applicants_persons_hbx_ids.include?(thhm.person_id)
              applicant = application_in_context.applicants.select { |applicant| applicant.person.hbx_id == thhm.person_id }.first
              verified_family.family_members.each do |verified_family_member|
                if verified_family_member.person.hbx_id == thhm.person_id
                  applicant.update_attributes({
                    medicaid_household_size: verified_family_member.medicaid_household_size,
                    magi_medicaid_category: verified_family_member.magi_medicaid_category,
                    magi_as_percentage_of_fpl: verified_family_member.magi_as_percentage_of_fpl,
                    magi_medicaid_monthly_income_limit: verified_family_member.magi_medicaid_monthly_income_limit,
                    magi_medicaid_monthly_household_income: verified_family_member.magi_medicaid_monthly_household_income,
                    is_without_assistance: verified_family_member.is_without_assistance,
                    is_ia_eligible: verified_family_member.is_insurance_assistance_eligible,
                    is_medicaid_chip_eligible: verified_family_member.is_medicaid_chip_eligible,
                    is_non_magi_medicaid_eligible: verified_family_member.is_non_magi_medicaid_eligible,
                    is_totally_ineligible: verified_family_member.is_totally_ineligible})
                end
              end
            end
          end
          #Applicant/TaxHouseholdMember block end
          #Eligibility determination start.
          if !verified_tax_households.map(&:eligibility_determinations).map(&:present?).include?(false)
            verified_eligibility_determination = vthh.eligibility_determinations.max_by(&:determination_date) #Finding the right Eligilbilty Determination

            #TODO find the right source Curam/Haven.
            source = "Haven"

            if tax_household.eligibility_determinations.build(
              benchmark_plan_id: benchmark_plan_id,
              max_aptc: verified_eligibility_determination.maximum_aptc.to_f > 0.00 ? verified_eligibility_determination.maximum_aptc : 0.00,
              csr_percent_as_integer: verified_eligibility_determination.csr_percent,
              determined_at: verified_eligibility_determination.determination_date,
              determined_on: verified_eligibility_determination.determination_date,
              aptc_csr_annual_household_income: verified_eligibility_determination.aptc_csr_annual_household_income,
              aptc_annual_income_limit: verified_eligibility_determination.aptc_annual_income_limit,
              csr_annual_income_limit: verified_eligibility_determination.csr_annual_income_limit,
              source: source
              ).save
            else
              throw(:processing_issue, "Failed to create Eligibility Determinations")
            end
          end
          #Eligibility determination end
        else
          #When taxhousehold does not exist in your DB
          throw(:processing_issue, "ERROR: Failed to find Tax Households in our DB with the ids in xml")
        end
      end
      self.save!
    end
  end

  def effective_ending_on_gt_effective_starting_on

    return if effective_ending_on.nil?
    return if effective_starting_on.nil?

    if effective_ending_on < effective_starting_on
      self.errors.add(:base, "The effective end date should be earlier or equal to effective start date")
    end
  end

  def parent
    raise "undefined parent family" unless self.family
    self.family
  end

  def irs_group=(new_irs_group)
    return unless new_irs_group.is_a? IrsGroup
    self.irs_group_id = new_irs_group._id
    @irs_group = new_irs_group
  end

  def irs_group
    return @irs_group if defined? @irs_group
    @irs_group = parent.irs_groups.find(self.irs_group_id)
  end

  def is_active?
    self.is_active
  end

  def latest_coverage_household
    return coverage_households.first if coverage_households.size == 1
    coverage_households.sort_by(&:submitted_at).last.submitted_at
  end

  def latest_active_tax_households
    tax_households.where(effective_ending_on: nil, is_eligibility_determined: true)
  end

  def latest_active_tax_households_with_year(year)
    tax_households = self.tax_households.tax_household_with_year(year)
    if TimeKeeper.date_of_record.year == year
      tax_households = self.tax_households.tax_household_with_year(year).active_tax_household
    end
    tax_households unless tax_households.empty?
  end

  def latest_tax_households_with_year(year)
    tax_households.tax_household_with_year(year)
  end

  # TODO: Refactor this. This will not work in the contect of FAA and multiple THHs.
  def end_multiple_thh(options = {})
    all_active_thh = tax_households.active_tax_household
    all_active_thh.group_by(&:group_by_year).select {|k, v| v.size > 1}.each_pair do |k, v|
      sorted_ath = active_thh_with_year(k).order_by(:'created_at'.asc)
      c = sorted_ath.count
      #for update eligibility manually
      sorted_ath.limit(c-1).update_all(effective_ending_on: Date.new(k, 12, 31)) if sorted_ath
    end
  end

  def latest_active_thh
    return tax_households.first if tax_households.length == 1
    tax_households.active_tax_household.order_by(:'created_at'.desc).first
  end

  def latest_active_thh_with_year(year)
    tax_households.tax_household_with_year(year).active_tax_household.order_by(:'created_at'.desc).first
  end

  def active_thh_with_year(year)
    tax_households.tax_household_with_year(year).active_tax_household
  end

  def build_thh_and_eligibility(max_aptc, csr, date, slcsp)
    th = tax_households.build(
        allocated_aptc: 0.0,
        effective_starting_on: Date.new(date.year, date.month, date.day),
        is_eligibility_determined: true,
        submitted_at: Date.today
    )

    th.tax_household_members.build(
        family_member: family.primary_family_member,
        is_subscriber: true,
        is_ia_eligible: true
    )

    deter = th.eligibility_determinations.build(
        source: "Admin",
        benchmark_plan_id: slcsp,
        max_aptc: max_aptc.to_f,
        csr_percent_as_integer: csr.to_i,
        determined_on: Date.today
    )

    deter.save!

    end_multiple_thh

    th.save!

    family.active_dependents.each do |fm|
      ath = latest_active_thh
      ath.tax_household_members.build(
          family_member: fm,
          is_subscriber: false,
          is_ia_eligible: true
      )
      ath.save!
    end
  end

  def applicant_ids
    th_applicant_ids = tax_households.inject([]) do |acc, th|
      acc + th.applicant_ids
    end
    ch_applicant_ids = coverage_households.inject([]) do |acc, ch|
      acc + ch.applicant_ids
    end
    hbxe_applicant_ids = hbx_enrollments.inject([]) do |acc, he|
      acc + he.applicant_ids
    end
    (th_applicant_ids + ch_applicant_ids + hbxe_applicant_ids).distinct
  end

  # This will set the effective_ending_on of previously active household to 1 day
  # before start of the current household's effective_starting_on
  def set_effective_ending_on
    return true unless self.effective_starting_on

    latest_household = self.family.latest_household
    return true if self == latest_household

    latest_household.effective_ending_on = self.effective_starting_on - 1.day
    true
  end

  def reset_is_active_for_previous
    latest_household = self.family.latest_household
    active_value = self.is_active
    latest_household.is_active = false
    self.is_active = active_value
    true
  end

  def set_submitted_at
    return true unless self.submitted_at.blank?

    self.submitted_at = tax_households.sort_by(&:updated_at).last.updated_at if tax_households.length > 0
    self.submitted_at = parent.submitted_at unless self.submitted_at
    true
  end

  def set_effective_starting_on
    return true unless self.effective_starting_on.blank?

    self.effective_starting_on =  parent.submitted_at
    true
  end

  def new_hbx_enrollment_from(employee_role: nil, coverage_household: nil, benefit_group: nil, benefit_group_assignment: nil, resident_role: nil, consumer_role: nil, benefit_package: nil, qle: false, submitted_at: nil, coverage_start: nil, enrollment_kind:nil, external_enrollment: false, opt_effective_on: nil)
    coverage_household = latest_coverage_household unless coverage_household.present?
    HbxEnrollment.new_from(
      employee_role: employee_role,
      resident_role: resident_role,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
      benefit_group_assignment: benefit_group_assignment,
      consumer_role: consumer_role,
      benefit_package: benefit_package,
      qle: qle,
      submitted_at: Time.now,
      external_enrollment: external_enrollment,
      coverage_start: coverage_start,
      opt_effective_on: opt_effective_on
    )
  end

  def create_hbx_enrollment_from(employee_role: nil, coverage_household: nil, benefit_group: nil, benefit_group_assignment: nil, consumer_role: nil, benefit_package: nil, submitted_at: nil)
    enrollment = new_hbx_enrollment_from(
      employee_role: employee_role,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
      benefit_group_assignment: benefit_group_assignment,
      consumer_role: consumer_role,
      benefit_package: benefit_package,
      submitted_at: Time.now
    )
    enrollment.save
    enrollment
  end

  def delete_hbx_enrollment(hbx_enrollment_id)
    hbx_enrollment = hbx_enrollments.detect {hbx_enrollment_id}
    if hbx_enrollment.present?
      benefit_group_assignment = hbx_enrollment.benefit_group_assignment

      if benefit_group_assignment.present?
        benefit_group_assignment.destroy! && hbx_enrollment.destroy!
      else
        hbx_enrollment.destroy!
      end
    else
      return false
    end
  end

  def remove_family_member(member)
    coverage_households.each do |c_household|
      c_household.remove_family_member(member)
    end
  end

  def enrolled_including_waived_hbx_enrollments
    #hbx_enrollments.coverage_selected_and_waived
    enrs = hbx_enrollments.coverage_selected_and_waived
    health_enr = enrs.detect { |a| a.coverage_kind == "health"}
    dental_enr = enrs.detect { |a| a.coverage_kind == "dental"}
    [health_enr , dental_enr].compact
  end

  def enrolled_hbx_enrollments
    hbx_enrollments.enrolled
  end

  def active_hbx_enrollments_with_aptc_by_year(year)
    hbx_enrollments.active.enrolled.with_aptc.by_year(year).where(changing: false).entries
  end

  def hbx_enrollments_with_aptc_by_date(date)
    hbx_enrollments.enrolled_and_renewing.with_aptc.by_year(date.year).gte(effective_on: date)
  end

  def hbx_enrollments_with_aptc_by_year(year)
    hbx_enrollments.enrolled_and_renewing.with_aptc.by_year(year)
  end

  def eligibility_determinations_for_year(year)
    tax_households.tax_household_with_year(year).inject([]) do |ed, th|
      ed << th.eligibility_determinations
      ed.flatten
    end
  end

  def create_new_tax_household(params)
    effective_date = params["effective_date"].to_date
    slcsp_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp_id

    th = tax_households.create(
      allocated_aptc: 0.0,
      effective_starting_on: Date.new(effective_date.year, effective_date.month, effective_date.day),
      is_eligibility_determined: true,
      submitted_at: TimeKeeper.datetime_of_record
    )

    th.eligibility_determinations.create(
      source: "Admin",
      benchmark_plan_id: slcsp_id,
      max_aptc: params["max_aptc"].to_f,
      csr_percent_as_integer: params["csr"].to_i,
      determined_on: TimeKeeper.datetime_of_record
    )

    params["family_members"].each do |person_hbx_id, thhm_info|
      person_id = Person.by_hbx_id(person_hbx_id).first.id
      family_member = family.family_members.where(person_id: person_id).first
      th.tax_household_members.create(
        :applicant_id => family_member.id,
        :is_subscriber => family_member.is_primary_applicant,
        thhm_info["pdc_type"].to_sym => true,
        :reason => thhm_info["reason"]
      )
    end

    end_multiple_thh
  end
end
