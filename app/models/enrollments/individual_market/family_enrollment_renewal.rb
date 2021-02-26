# frozen_string_literal: true

class Enrollments::IndividualMarket::FamilyEnrollmentRenewal
  attr_accessor :enrollment, :renewal_coverage_start, :assisted, :aptc_values
  CAT_AGE_OFF_HIOS_IDS = ["94506DC0390008", "86052DC0400004"]

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
      puts "#{enrollment.hbx_id}---#{e.inspect}" # unless Rails.env.test?
      @logger.info "Enrollment renewal failed for #{enrollment.hbx_id} with Exception: #{e.backtrace}"
    end
  end

  def clone_enrollment
    renewal_enrollment = HbxEnrollment.new
    renewal_enrollment.family_id = @enrollment.family_id
    renewal_enrollment.household_id = @enrollment.household_id
    renewal_enrollment.consumer_role_id = @enrollment.consumer_role_id
    renewal_enrollment.resident_role_id = @enrollment.resident_role_id
    renewal_enrollment.effective_on = renewal_coverage_start
    renewal_enrollment.coverage_kind = @enrollment.coverage_kind
    renewal_enrollment.enrollment_kind = "open_enrollment"
    renewal_enrollment.kind = @enrollment.kind
    renewal_enrollment.hbx_enrollment_members = clone_enrollment_members
    renewal_enrollment.product_id = fetch_product_id(renewal_enrollment)
    renewal_enrollment.is_any_enrollment_member_outstanding = @enrollment.is_any_enrollment_member_outstanding
    save_renewal_enrollment(renewal_enrollment)

    # elected aptc should be the minimun between applied_aptc and EHB premium.
    renewal_enrollment = assisted_enrollment(renewal_enrollment) if @assisted

    renewal_enrollment
  end

  def fetch_product_id(renewal_enrollment)
    # TODO: Fetch proper csr product as the family might be eligible for a
    # different csr value than that of given externally.

    (can_renew_assisted_product?(renewal_enrollment) ? assisted_renewal_product : renewal_product)
  end

  def can_renew_assisted_product?(renewal_enrollment)
    return false unless @assisted

    tax_household = enrollment.family.active_household.latest_active_thh_with_year(renewal_coverage_start.year)
    members = tax_household.tax_household_members
    enrollment_members_in_thh = members.where(:applicant_id.in => renewal_enrollment.hbx_enrollment_members.map(&:applicant_id))
    enrollment_members_in_thh.all? {|m| m.is_ia_eligible == true}
  end

  def assisted_enrollment(renewal_enrollment)
    renewal_service = Services::IvlEnrollmentRenewalService.new(renewal_enrollment)
    renewal_service.assign(@aptc_values)
  end

  def is_dependent_dropped?
    @dependent_age_off
  end

  # Assisted
  # Tax household > eligibility determinations
  #  - latest eligibility determation
  #  - current CSR elgibility kind
  #  - max APTC
  def renewal_eligiblity_determination; end

  # Cat product ageoff
  # Eligibility determination CSR change
  def renewal_product
    if @enrollment.coverage_kind == 'dental'
      renewal_product = @enrollment.product.renewal_product_id
    elsif has_catastrophic_product? && is_cat_product_ineligible?
      renewal_product = fetch_cat_age_off_product(@enrollment.product)
      raise "#{renewal_coverage_start.year} Catastrophic age off product missing on HIOS id #{@enrollment.product.hios_id}" if renewal_product.blank?
    else
      renewal_product = if @enrollment.product.csr_variant_id == '01' || has_catastrophic_product?
                          @enrollment.product.renewal_product_id
                        else
                          ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(renewal_coverage_start.year).where(
                            {:hios_id => "#{@enrollment.product.renewal_product.hios_base_id}-01"}
                          ).first.id
                        end
    end

    raise "#{renewal_coverage_start.year} renewal product missing on HIOS id #{@enrollment.product.hios_id}" if renewal_product.blank?

    renewal_product
  end

  def fetch_csr_variant
    @aptc_values[:csr_amt] == '0' ? '01' : EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP["csr_#{@aptc_values[:csr_amt]}"]
  end

  def fetch_cat_age_off_product(product)
    # As per ticket: 61716
    # FIXME: DON'T EVER DO THIS!
    # We are incrementing the year to do for all future years too,
    # which won't work because the HIOS IDs won't be the same
    if renewal_coverage_start.year.to_i >= 2020 && CAT_AGE_OFF_HIOS_IDS.include?(product.hios_base_id)
      base_id = if product.hios_base_id == "94506DC0390008"
                  "94506DC0390010"
                elsif product.hios_base_id == "86052DC0400004"
                  "86052DC0400010"
                end
      ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(renewal_coverage_start.year).where(
        {:hios_id => "#{base_id}-01"}
      ).first.id
    else
      product.catastrophic_age_off_product_id
    end
  end

  def assisted_renewal_product
    # TODO: Make sure tax households create script treats 0 as 100
    if @aptc_values[:csr_amt].present? && @enrollment.product.metal_level == "silver"
      csr_variant = fetch_csr_variant
      product = fetch_product(csr_variant)
      return product.id if product

      fetch_product("01").id
    else
      @enrollment.product.renewal_product_id
    end
  end

  def fetch_product(csr_variant)
    ::BenefitMarkets::Products::HealthProducts::HealthProduct.by_year(renewal_coverage_start.year).where(
      {:hios_id => "#{@enrollment.product.renewal_product.hios_base_id}-#{csr_variant}"}
    ).first
  end

  def has_catastrophic_product?
    @enrollment.product.metal_level_kind == :catastrophic
  end

  def is_cat_product_ineligible?
    @enrollment.hbx_enrollment_members.any? do |member|
      member.person.age_on(renewal_coverage_start) > 29
    end
  end

  # rubocop:disable Style/RedundantReturn
  def eligible_to_get_covered?(member)
    child_relations = %w[child ward foster_child adopted_child]

    return true unless child_relations.include?(member.family_member.relationship)

    if EnrollRegistry.feature_enabled?(:age_off_relaxed_eligibility)
      dependent_coverage_eligible = ::EnrollRegistry[:age_off_relaxed_eligibility] do
        {
          effective_on: renewal_coverage_start,
          family_member: member&.family_member,
          market_key: :aca_individual_dependent_age_off,
          relationship_kind: member.family_member.relationship
        }
      end
      return true if dependent_coverage_eligible.success?
    elsif child_relations.include?(member.family_member.relationship)
      return true if member.person.age_on(renewal_coverage_start.prev_day) < 26
    end

    @dependent_age_off ||= true
    return false
  end
  # rubocop:enable Style/RedundantReturn

  def eligible_enrollment_members
    @enrollment.hbx_enrollment_members.reject do |member|
      member.person.is_disabled || !eligible_to_get_covered?(member)
    end
  end

  def clone_enrollment_members
    old_enrollment_members = eligible_enrollment_members
    raise  "unable to generate enrollment with hbx_id #{@enrollment.hbx_id} due to no enrollment members not present" if old_enrollment_members.blank?

    old_enrollment_members.inject([]) do |members, hbx_enrollment_member|
      members << HbxEnrollmentMember.new({ applicant_id: hbx_enrollment_member.applicant_id,
                                           eligibility_date: renewal_coverage_start,
                                           coverage_start_on: renewal_coverage_start,
                                           is_subscriber: hbx_enrollment_member.is_subscriber })
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
