class Enrollments::IndividualMarket::FamilyEnrollmentRenewal

  attr_accessor :enrollment, :renewal_coverage_start, :assisted, :aptc_values

  def initialize
    @logger = Logger.new("#{Rails.root}/log/ivl_open_enrollment_begin_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log") unless defined? @logger
  end

  def renew
    @dependent_age_off = false

    begin
      renewal_enrollment = clone_enrollment
      if is_dependent_dropped?
        renewal_enrollment.aasm_state = 'coverage_selected'
        renewal_enrollment.workflow_state_transitions.build(from_state: 'shopping', to_state: 'coverage_selected')
      else
        renewal_enrollment.renew_enrollment
      end

      # renewal_enrollment.decorated_hbx_enrollment
      @dependent_age_off = nil
      save_renewal_enrollment(renewal_enrollment)
    rescue Exception => e
      puts "#{enrollment.hbx_id}---#{e.inspect}" unless Rails.env.test?
      @logger.info "Enrollment renewal failed for #{enrollment.hbx_id} with Exception: #{e.to_s}"
    end
  end

  def clone_enrollment
    renewal_enrollment = @enrollment.family.active_household.hbx_enrollments.new
    renewal_enrollment.family_id = @enrollment.family.id
    renewal_enrollment.consumer_role_id = @enrollment.consumer_role_id
    renewal_enrollment.effective_on = renewal_coverage_start
    renewal_enrollment.coverage_kind = @enrollment.coverage_kind
    renewal_enrollment.enrollment_kind = "open_enrollment"
    renewal_enrollment.kind = "individual"
    renewal_enrollment.plan_id = (@assisted ? assisted_renewal_plan : renewal_plan)
    renewal_enrollment.elected_aptc_pct = @enrollment.elected_aptc_pct
    renewal_enrollment.hbx_enrollment_members = clone_enrollment_members
    renewal_enrollment.is_any_enrollment_member_outstanding = @enrollment.is_any_enrollment_member_outstanding

    # elected aptc should be the minimun between applied_aptc and EHB premium.
    if @assisted
      ehb_premium = (renewal_enrollment.total_premium * renewal_enrollment.plan.ehb)
      applied_aptc_amt = [@aptc_values[:applied_aptc].to_f, ehb_premium].min
      renewal_enrollment.applied_aptc_amount = applied_aptc_amt

      if applied_aptc_amt == @aptc_values[:applied_aptc].to_f
        renewal_enrollment.elected_aptc_pct = (@aptc_values[:applied_percentage].to_f/100.0)
      else
        renewal_enrollment.elected_aptc_pct = (applied_aptc_amt / @aptc_values[:"max_aptc"].to_f)
      end
    end

    renewal_enrollment
  end

  def is_dependent_dropped?
    @dependent_age_off
  end

  # Assisted
  # Tax household > eligibility determinations
  #  - latest eligibility determation
  #  - current CSR elgibility kind
  #  - max APTC
  def renewal_eligiblity_determination
  end

  # Cat plan ageoff
  # Eligibility determination CSR change
  def renewal_plan
    if @enrollment.coverage_kind == 'dental'
      renewal_plan = @enrollment.plan.renewal_plan_id
    else
      if has_catastrophic_plan? && is_cat_plan_ineligible?
        renewal_plan = @enrollment.plan.cat_age_off_renewal_plan_id
        if renewal_plan.blank?
          raise "#{renewal_coverage_start.year} Catastrophic age off plan missing on HIOS id #{@enrollment.plan.hios_id}"
        end
      else
        if @enrollment.plan.csr_variant_id == '01' || has_catastrophic_plan?
          renewal_plan = @enrollment.plan.renewal_plan_id
        else
          renewal_plan = Plan.where({
            :active_year => renewal_coverage_start.year, 
            :hios_id => "#{@enrollment.plan.renewal_plan.hios_base_id}-01"
            }).first.id
        end
      end
    end

    if renewal_plan.blank?
      raise "#{renewal_coverage_start.year} renewal plan missing on HIOS id #{@enrollment.plan.hios_id}"
    end
    
    renewal_plan
  end

  def is_csr?
    csr_plan_variants = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.except('csr_100').values
    (@enrollment.plan.metal_level == "silver") && (csr_plan_variants.include?(@enrollment.plan.csr_variant_id))
  end

  def assisted_renewal_plan
    # TODO: Make sure tax households create script treats 0 as 100 
    if is_csr?
      if @aptc_values[:csr_amt] == '0'
        csr_variant = '01'
      else
        csr_variant = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP["csr_#{@aptc_values[:csr_amt]}"]
      end

      Plan.where({
        :active_year => renewal_coverage_start.year, 
        :hios_id => "#{@enrollment.plan.renewal_plan.hios_base_id}-#{csr_variant}"
      }).first.id
    else
      @enrollment.plan.renewal_plan_id
    end
  end

  def has_catastrophic_plan?
    @enrollment.plan.metal_level == 'catastrophic'       
  end

  def is_cat_plan_ineligible?
    @enrollment.hbx_enrollment_members.any? do |member| 
      member.person.age_on(renewal_coverage_start) > 29
    end
  end

  def eligible_to_get_covered?(member)
    child_relations = %w(child ward foster_child adopted_child)

    if child_relations.include?(member.family_member.relationship)
      return true if member.person.age_on(renewal_coverage_start.prev_day) < 26
      @dependent_age_off = true unless @dependent_age_off
      return false
    else
      true
    end
  end

  def eligible_enrollment_members
    @enrollment.hbx_enrollment_members.reject do |member|
      member.person.is_disabled || !eligible_to_get_covered?(member)
    end
  end

  def clone_enrollment_members
    eligible_enrollment_members.inject([]) do |members, hbx_enrollment_member|
      members << HbxEnrollmentMember.new({
        applicant_id: hbx_enrollment_member.applicant_id,
        eligibility_date: renewal_coverage_start,
        coverage_start_on: renewal_coverage_start,
        is_subscriber: hbx_enrollment_member.is_subscriber
      })
    end
  end

  def save_renewal_enrollment(renewal_enrollment)
    if renewal_enrollment.save
      renewal_enrollment
    else
      message = "Enrollment: #{@enrollment.hbx_id}, \n" \
      "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"
      
      @logger.info message
    end
  end
end