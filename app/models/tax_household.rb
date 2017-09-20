# A set of applicants, grouped according to IRS and ACA rules, who are considered a single unit
# when determining eligibility for Insurance Assistance and Medicaid

class TaxHousehold
  require 'autoinc'

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Autoinc
  include HasFamilyMembers
  include Acapi::Notifiers
  include SetCurrentUser

  before_create :set_effective_starting_on

  embedded_in :application, class_name: "FinancialAssistance::Application"

  field :hbx_assigned_id, type: Integer
  increments :hbx_assigned_id, seed: 9999

  field :allocated_aptc, type: Money, default: 0.00
  field :is_eligibility_determined, type: Boolean, default: false

  field :effective_starting_on, type: Date
  field :effective_ending_on, type: Date
  field :submitted_at, type: DateTime

  #accepts_nested_attributes_for :tax_household_members

  scope :tax_household_with_year, ->(year) { where( effective_starting_on: (Date.new(year)..Date.new(year).end_of_year)) }
  scope :active_tax_household, ->{ where(effective_ending_on: nil) }

  # def latest_eligibility_determination
  #   eligibility_determinations.sort {|a, b| a.determined_on <=> b.determined_on}.last
  # end

  # def current_csr_eligibility_kind
  #   eligibility_determination.present? ? eligibility_determination.csr_eligibility_kind : "csr_100"
  # end

  def current_csr_percent
    preferred_eligibility_determination.present? ? preferred_eligibility_determination.csr_percent : 0
  end

  def current_max_aptc
    preferred_eligibility_determination.present? ? preferred_eligibility_determination.max_aptc : 0
  end

  def aptc_members
    active_applicants.find_all(&:is_ia_eligible?)
  end

  def aptc_ratio_by_member
    # if APTC is $100, we need to apportion it between member
    # For example, given family of 4, with 2 adults & 2 children, all who are eligible
    # Based on SLCSP, we will compute ratio for each member based on premium cost
    # So, if total family premium cost is $1,000, adult premium cost is $350/each and
    # child premium cost is $150/each, APTC ratio will be 35% to each adult and
    # 15% to each child

    # Benchmark Plan: use SLCSP premium rates to determine ratios
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    #current_benefit_coverage_period = benefit_sponsorship.current_benefit_period
    #slcsp = current_benefit_coverage_period.second_lowest_cost_silver_plan
    benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(effective_starting_on)}
    slcsp = benefit_coverage_period.second_lowest_cost_silver_plan

    # Look up premiums for each aptc_member
    benchmark_member_cost_hash = {}
    aptc_members.select { |thm| thm.is_medicaid_chip_eligible == false && thm.is_without_assistance == false && thm.is_totally_ineligible == false}.each do |member|
      #TODO use which date to calculate premiums by slcp
      premium = slcsp.premium_for(effective_starting_on, member.age_on_effective_date)
      benchmark_member_cost_hash[member.family_member.id.to_s] = premium
    end

    # Sum premium total for aptc_members
    sum_premium_total = benchmark_member_cost_hash.values.sum.to_f

    # Compute the ratio
    ratio_hash = {}
    benchmark_member_cost_hash.each do |member_id, cost|
      ratio_hash[member_id] = cost/sum_premium_total
    end

    ratio_hash
  rescue => e
    log(e.message, {:severity => 'critical'})
    {}
  end

  # Pass hbx_enrollment and get the total amount of APTC available by hbx_enrollment_members
  def total_aptc_available_amount_for_enrollment(hbx_enrollment)
    return 0 if hbx_enrollment.blank?
    hbx_enrollment.hbx_enrollment_members.reduce(0) do |sum, member|
      sum + (aptc_available_amount_by_member[member.applicant_id.to_s] || 0)
    end
  end

  def aptc_available_amount_by_member
    # Find HbxEnrollments for aptc_members in the current plan year where they have used aptc
    # subtract from available amount
    aptc_available_amount_hash = {}
    aptc_ratio_by_member.each do |member_id, ratio|
      aptc_available_amount_hash[member_id] = current_max_aptc.to_f * ratio
    end

    # FIXME should get hbx_enrollments by effective_starting_on
    family.active_household.hbx_enrollments_with_aptc_by_year(effective_starting_on.year).map(&:hbx_enrollment_members).flatten.each do |enrollment_member|
      applicant_id = enrollment_member.applicant_id.to_s
      if aptc_available_amount_hash.has_key?(applicant_id)
        aptc_available_amount_hash[applicant_id] -= (enrollment_member.applied_aptc_amount || 0).try(:to_f)
        aptc_available_amount_hash[applicant_id] = 0 if aptc_available_amount_hash[applicant_id] < 0
      end
    end
    aptc_available_amount_hash
  end

  def total_aptc_available_amount
    aptc_available_amount_by_member.present? ? aptc_available_amount_by_member.values.sum : 0
  end

  # Pass a list of tax_household_members and get amount of APTC available
  def aptc_available_amount_for_enrollment(hbx_enrollment, plan, elected_aptc)
    # APTC may be used only for Health, return 0 if plan.coverage_kind == "dental"
    aptc_available_amount_hash_for_enrollment = {}

    total_aptc_available_amount = total_aptc_available_amount_for_enrollment(hbx_enrollment)
    elected_pct = total_aptc_available_amount > 0 ? (elected_aptc.to_f / total_aptc_available_amount.to_f) : 0
    decorated_plan = UnassistedPlanCostDecorator.new(plan, hbx_enrollment)
    hbx_enrollment.hbx_enrollment_members.each do |enrollment_member|
      given_aptc = (aptc_available_amount_by_member[enrollment_member.applicant_id.to_s] || 0) * elected_pct
      ehb_premium = decorated_plan.premium_for(enrollment_member) * plan.ehb
      if plan.coverage_kind == "dental"
        aptc_available_amount_hash_for_enrollment[enrollment_member.applicant_id.to_s] = 0
      else
        aptc_available_amount_hash_for_enrollment[enrollment_member.applicant_id.to_s] = [given_aptc, ehb_premium].min
      end
    end
    aptc_available_amount_hash_for_enrollment

    # premium_total = as_dollars(policy.pre_amt_tot)
    # given_aptc = as_dollars(policy.applied_aptc)
    # max_aptc = as_dollars(premium_total * plan.ehb)
    # correct_aptc = (given_aptc > max_aptc) ? max_aptc : given_aptc
    # policy.applied_aptc = correct_aptc
    # $70
  end

  # Income sum of all tax filers in this Household for specified year
  def total_incomes_by_year
    applicant_links.inject({}) do |acc, per|
      p_incomes = per.financial_statements.inject({}) do |acc, ae|
        acc.merge(ae.total_incomes_by_year) { |k, ov, nv| ov + nv }
      end
      acc.merge(p_incomes) { |k, ov, nv| ov + nv }
    end
  end

  #TODO: return count for adults (21-64), children (<21) and total
  def size
    members.size
  end

  def family
    return nil unless application
    application.family
  end

  def is_eligibility_determined?
    if self.elegibility_determinizations.size > 0
      true
    else
      false
    end
  end

  #primary applicant is the tax household member who is the subscriber
  def primary_applicant
    active_applicants.each do |applicant|
      return applicant if applicant.family_member.is_primary_applicant?
    end
  end

  def applicants
    return nil unless application.active_applicants
    application.active_applicants.where(tax_household_id: self.id)
  end

  def any_applicant_ia_eligible?
    return nil unless active_applicants.present?
    active_applicants.map(&:is_ia_eligible).include?(true)
  end

  def preferred_eligibility_determination
    return nil unless family.active_approved_application
    eds = application.eligibility_determinations.where(tax_household_id: self.id)
    admin_ed = eds.where(source: "Admin").first
    curam_ed = eds.where(source: "Curam").first
    return admin_ed if admin_ed.present? #TODO: Pick the last admin, because you may have multiple.
    return curam_ed if curam_ed.present?
    return eds.max_by(&:determined_at)
  end

  def eligibility_determinations
    return nil unless family.active_approved_application
    family.active_approved_application.eligibility_determinations.where(tax_household_id: self.id)
  end

  def set_effective_starting_on
    write_attributes(effective_starting_on: TimeKeeper.date_of_record)
  end
end
