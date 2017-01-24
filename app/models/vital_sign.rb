class VitalSign
  include Mongoid::Document

  attr_reader :start_at, :end_at

  # DateTime that DCHL Enroll App went live
  ZERO_HOUR = DateTime.new(2015,10,27,23,43,0,'-4')

  def initialize(start_at: ZERO_HOUR, end_at: TimeKeeper.datetime_of_record)
    @start_at = start_at
    @end_at = end_at
  end

  def families_to_eligibility_determinations(family_list)
    family_list.flat_map() do |family|
      family.households.flat_map() do |household|
        household.tax_households.flat_map() do |tax_household|
          tax_household.eligibility_determinations
        end
      end
    end
  end

  def accounts_created
    User.gte(created_at: @start_at).lte(created_at: @end_at)
  end

  def all_plan_shopping
    Family.and(
        {:"households.hbx_enrollments.created_at".gte => @start_at},
        {:"households.hbx_enrollments.created_at".lte => @end_at}
      ).to_a
  end

  def all_shop_non_oe_completed_enrollments
    all_shop_completed_enrollments.select do |en|
      en.benefit_group.employer_profile.aasm_state == "binder_paid"
    end
  end

  def all_shop_completed_enrollments
    all_completed_enrollments.select do |en|
      en.consumer_role_id.blank?
    end
  end

  def all_individual_completed_enrollments
    all_completed_enrollments.select do |en|
      !en.consumer_role_id.blank?
    end
  end

  def other_shop_completed_enrollments 
    fams = Family.unscoped.where({
      "households.hbx_enrollments" => {
        "$elemMatch" => {
          "effective_on" => {
            "$gt" => Date.new(2015,11,30),
            "$lt" => Date.new(2016,1,1)
          },
          "aasm_state" => { "$nin" => [
              "shopping", "inactive", "coverage_canceled", "coverage_terminated"
          ]}
        }
      }
    })
    puts fams.count

    all_pols = fams.flat_map(&:households).flat_map(&:hbx_enrollments)
    all_pols.select do |pol|
      pol.consumer_role_id.blank? &&
        (!["shopping", "inactive", "coverage_canceled", "coverage_terminated"].include?(pol.aasm_state.to_s))
    end
  end

  def all_completed_enrollments
    fams = Family.unscoped.where({
      "households.hbx_enrollments" => {
        "$elemMatch" => {
          "created_at" => { "$gte" => @start_at, "$lte" => @end_at},
           "aasm_state" => { "$nin" => [
              "shopping", "inactive", "coverage_canceled", "coverage_terminated"
           ]}
        }
      }
    })

    all_pols = fams.flat_map(&:households).flat_map(&:hbx_enrollments)
    all_pols.select do |pol|
      (!pol.created_at.blank?) &&
      (pol.created_at >= @start_at) &&
      (pol.created_at <= @end_at) &&
        (!["shopping", "inactive", "coverage_canceled", "coverage_terminated"].include?(pol.aasm_state.to_s)) &&
      (pol.effective_on < Date.new(2016,1,1))
    end
  end

  def all_completed_enrollments_by_created_at
    fams = Family.unscoped.where({
      "households.hbx_enrollments" => {
        "$elemMatch" => {
          "created_at" => { "$gte" => @start_at, "$lte" => @end_at},
          "effective_on" => { "$lt" => Date.new(2016,1,1) },
           "aasm_state" => { "$nin" => [
              "shopping", "inactive", "coverage_canceled", "coverage_terminated"
           ]}
        }
      }
    })

    all_pols = fams.flat_map(&:households).flat_map(&:hbx_enrollments)
    all_pols.select do |pol|
      (!pol.created_at.blank?) &&
      (pol.created_at >= @start_at) &&
      (pol.created_at <= @end_at) &&
        (!["shopping", "inactive", "coverage_canceled", "coverage_terminated"].include?(pol.aasm_state.to_s)) &&
      (pol.effective_on < Date.new(2016,1,1))
    end
  end

  def all_completed_enrollments_by_submitted_at
    fams = Family.unscoped.where({
      "households.hbx_enrollments" => {
        "$elemMatch" => {
          "submitted_at" => { "$gte" => @start_at, "$lte" => @end_at},
          "effective_on" => { "$lt" => Date.new(2016,1,1) },
           "aasm_state" => { "$nin" => [
              "shopping", "inactive", "coverage_canceled", "coverage_terminated"
           ]}
        }
      }
    })

    all_pols = fams.flat_map(&:households).flat_map(&:hbx_enrollments)
    all_pols.select do |pol|
      (!pol.submitted_at.blank?) &&
      (pol.submitted_at >= @start_at) &&
      (pol.submitted_at <= @end_at) &&
        (!["shopping", "inactive", "coverage_canceled", "coverage_terminated"].include?(pol.aasm_state.to_s)) &&
      (pol.effective_on < Date.new(2016,1,1))
    end
  end

  def all_completed_2016
    fams = Family.unscoped.where({
      "households.hbx_enrollments" => {
        "$elemMatch" => {
           "effective_on" => Date.new(2016,1,1),
           "aasm_state" => { "$nin" => [
              "shopping", "inactive", "coverage_canceled", "coverage_terminated"
           ]}
        }
      }
    })

    all_pols = fams.flat_map(&:households).flat_map(&:hbx_enrollments)
    all_pols.select do |pol|
        (!["shopping", "inactive", "coverage_canceled", "coverage_terminated"].include?(pol.aasm_state.to_s)) &&
        (pol.effective_on == Date.new(2016,1,1))
    end
  end

  def all_shop_2016
    all_completed_2016.select do |en|
      en.consumer_role_id.blank?
    end
  end

  def all_individual_2016
    all_completed_2016.select do |en|
      !en.consumer_role_id.blank?
    end
  end

  def all_enrollments
    families = Family.all_enrollments.and(
        {:"households.hbx_enrollments.created_at".gte => @start_at},
        {:"households.hbx_enrollments.created_at".lte => @end_at}
      ).to_a

    @all_enrollments = families.flat_map() do |family|
      family.households.flat_map() do |household|
        household.hbx_enrollments.enrolled.gte(created_at: @start_at).lte(created_at: @end_at).and(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES)
      end
    end
  end

  def all_individual_eligibility_determinations
    families = Family.and(
        {:"households.tax_households.eligibility_determinations.determined_on".gte => @start_at},
        {:"households.tax_households.eligibility_determinations.determined_on".lte => @end_at}
      )

    @all_individual_eligibility_determinations = families.flat_map() do |family|
      family.households.flat_map() do |household|
        household.tax_households.flat_map() do |tax_household|
          tax_household.eligibility_determinations.gte(determined_on: @start_at).lte(determined_on: @end_at)
        end
      end
    end
  end

  def all_active_individual_eligibility_determinations
    all_individual_eligibility_determinations unless defined? @all_individual_eligibility_determinations
    @all_individual_eligibility_determinations.select { |determination| determination.tax_household.effective_ending_on.blank? }
  end

# v.all_active_individual_eligibility_determinations.each { |ed| puts "#{ed.max_aptc}" if ed.max_aptc > 0 }
  def all_active_assistance_eligible_individual_eligibility_determinations
    all_active_individual_eligibility_determinations.select { |determination| determination.max_aptc > 0 }
  end

  def enrollment_counts_by_family
    all_enrollments unless defined? @all_enrollments
    @all_enrollments.reduce(Hash.new(0)) {|counts, hbx_enrollment| counts[hbx_enrollment.household.family._id] += 1; counts }
  end

  def all_shop_enrollments
    all_enrollments unless defined? @all_enrollments
    @all_enrollments.select { |enrollment| ['employer_sponsored', 'employer_sponsored_cobra'].include? enrollment.kind }
  end

  def all_individual_enrollments
    all_enrollments unless defined? @all_enrollments
    @all_enrollments.select { |enrollment| enrollment.kind == "individual" }
  end

  def individual_unassisted_qhp_enrollments
    all_individual_enrollments.select { |enrollment| enrollment.household.family.e_case_id.blank? }
  end

  def individual_assisted_qhp_enrollments
    all_individual_enrollments.select { |enrollment| enrollment.household.family.e_case_id.present? }
  end

  def individual_assisted_qhp_enrollments_with_applied_aptc
    all_individual_enrollments.select { |enrollment| enrollment.applied_aptc_amount > 0.0 }
  end

  def is_health_enrollment?(enrollment)
    enrollment.plan.coverage_kind == "health"
  end

  def is_dental_enrollmant?(enrollment)
    enrollment.plan.coverage_kind == "dental"
  end

  def transferred_to_curam
  end

  def accounts_screened
  end

  def iam_new_account_requests
  end

  def ivl_assisted_eligibility_determinations_unmatched
  end


end
