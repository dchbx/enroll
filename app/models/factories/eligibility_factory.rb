# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
# This factory can be used for all eligibilities related projects.
# Currently Applied: Passive Renewals.
# Future Applicable locations: Plan Shopping Controller, APTC tool, Self Service.
module Factories
  class EligibilityFactory

    def initialize(enrollment_id, selected_aptc = nil, product_ids = [])
      @enrollment = HbxEnrollment.where(id: enrollment_id.to_s).first
      raise "Cannot find a valid enrollment with given enrollment id" unless @enrollment

      @family = @enrollment.family
      set_applicable_aptc_attrs(selected_aptc, product_ids) if product_ids.present? && selected_aptc
    end

    # returns hash of total_aptc, aptc_breakdown_by_member and csr_value
    def fetch_available_eligibility
      available_eligibility_hash = fetch_enrolling_available_aptcs.merge(fetch_csr)
=======
=======
# This factory can be used for all eligibilities related projects.
# Currently Applied: Passive Renewals.
# Future Applicable locations: Plan Shopping Controller, APTC tool, Self Service.
>>>>>>> 79240e1099... Refs #42845, removed un-used code and additional tests for Renewal Services
module Factories
  class EligibilityFactory

    def initialize(enrollment_id, selected_aptc = nil, product_ids = [])
      @enrollment = HbxEnrollment.find(enrollment_id)
      raise "Cannot find a valid enrollment with given enrollment id" unless @enrollment

      @family = @enrollment.family
      set_applicable_aptc_attrs(selected_aptc, product_ids) if product_ids.present? && selected_aptc
    end

    # returns hash of total_aptc, aptc_breakdown_by_member and csr_value
    def fetch_available_eligibility
<<<<<<< HEAD
<<<<<<< HEAD
      available_eligibility_hash = fetch_aptc.merge(fetch_csr)
>>>>>>> 20aa6cfd8a... Refs #42128, APTC Service setup
=======
      available_eligibility_hash = fetch_available_aptc.merge(fetch_csr)
>>>>>>> 52422f4dc1... Refs #42128, ApplicableAptcService setup
=======
      available_eligibility_hash = fetch_enrolling_available_aptcs.merge(fetch_csr)
>>>>>>> 28e3b77e09... Refs #42128, BenchMark implementation
      total_aptc = available_eligibility_hash[:aptc].values.inject(0, :+)
      available_eligibility_hash.merge({:total_available_aptc => total_aptc})
    end

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    # returns hash of product_id to applicable_aptc mappings
    def fetch_applicable_aptcs
      raise "Cannot process without selected_aptc: #{@selected_aptc} and product_ids: #{@product_ids}" if @selected_aptc.nil? || @product_ids.empty?

      @available_aptc ||= fetch_available_eligibility[:total_available_aptc]

      # TODO: Return a has of plan_id, applicable aptcs.
=======
=======
    # returns hash of product_id to applicable_aptc mappings
>>>>>>> 48d8acd91a... Refs #42128, comments
    def fetch_applicable_aptcs
      raise "Cannot process without #{@selected_aptc} and #{@product_ids}" if @selected_aptc.nil? || @product_ids.empty?

      @available_aptc ||= fetch_available_eligibility[:total_available_aptc]

<<<<<<< HEAD
>>>>>>> 911d0ff865... Refs #42128, Enhance ApplicableAptcService to calculate premiums for given plans
=======
      # TODO: Return a has of plan_id, applicable aptcs.
>>>>>>> 4d43c731b8... Refs #42128, rubocop
      @product_ids.inject({}) do |products_aptcs_hash, product_id|
        product_aptc = applicable_aptc_hash(product_id)
        products_aptcs_hash.merge!(product_aptc) unless product_aptc.empty?
        products_aptcs_hash
      end
<<<<<<< HEAD
    end

    private

    def applicable_aptc_hash(product_id)
      # We still consider AvailableAptc in this calculation because the
      # :applied_aptc(ElectedAptc) is given externally for Passive Renewals
      # and not calculated by the EA.

      applicable_aptc = [@available_aptc, @selected_aptc, ehb_premium(product_id)].min
      { product_id => applicable_aptc }
    end

    def set_applicable_aptc_attrs(selected_aptc, product_ids)
      @selected_aptc = selected_aptc
      @product_ids = product_ids
    end

    def ehb_premium(product_id)
      product = ::BenefitMarkets::Products::Product.find(product_id)
      premium_amount = fetch_total_premium(product)
      premium_amount * product.ehb
    end

    def fetch_total_premium(product)
      cost_decorator = @enrollment.ivl_decorated_hbx_enrollment(product)
      cost_decorator.total_premium
    end

=======
    private

>>>>>>> 20aa6cfd8a... Refs #42128, APTC Service setup
=======
    def fetch_applicable_aptc
      [@selected_aptc, @ehb_premium].min if @product && @selected_aptc
=======
>>>>>>> 911d0ff865... Refs #42128, Enhance ApplicableAptcService to calculate premiums for given plans
    end

    private

    def applicable_aptc_hash(product_id)
      # We still consider AvailableAptc in this calculation because the
      # :applied_aptc(ElectedAptc) is given externally for Passive Renewals
      # and not calculated by the EA.

      applicable_aptc = [@available_aptc, @selected_aptc, ehb_premium(product_id)].min
      { product_id => applicable_aptc }
    end

    def set_applicable_aptc_attrs(selected_aptc, product_ids)
      @selected_aptc = selected_aptc
      @product_ids = product_ids
    end

    def ehb_premium(product_id)
      product = ::BenefitMarkets::Products::Product.find(product_id)
      premium_amount = fetch_total_premium(product)
      premium_amount * product.ehb
    end

    def fetch_total_premium(product)
      cost_decorator = @enrollment.ivl_decorated_hbx_enrollment(product)
      cost_decorator.total_premium
    end

>>>>>>> 52422f4dc1... Refs #42128, ApplicableAptcService setup
    def shopping_member_ids
      @enrollment.hbx_enrollment_members.pluck(:applicant_id).map(&:to_s)
    end

    def tax_households
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
      # TODO: Refactor this accordingly once FAA is enabled.
      @family.active_household.latest_active_tax_household_with_year(@enrollment.effective_on.year).to_a.compact
    end

    def shopping_tax_members
      tax_households.flat_map(&:tax_members).select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) }
=======
      @family.active_household.tax_households
=======
=======
      # TODO: Refactor this accordingly once FAA is enabled.
<<<<<<< HEAD
>>>>>>> 79240e1099... Refs #42845, removed un-used code and additional tests for Renewal Services
      @family.active_household.latest_active_tax_household_with_year(@enrollment.effective_on.year).to_a
>>>>>>> 7756264eea... Refs #42128, Additional tests added for the Single Tax Household cases
=======
      @family.active_household.latest_active_tax_household_with_year(@enrollment.effective_on.year).to_a.compact
>>>>>>> 0c442bac29... Refs #42128, Fix for shopping members without associated TaxHouseholdMembers
    end

    def shopping_tax_members
<<<<<<< HEAD
      tax_households.flat_map(&:tax_household_members).select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) }
>>>>>>> 20aa6cfd8a... Refs #42128, APTC Service setup
=======
      tax_households.flat_map(&:tax_members).select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) }
>>>>>>> e1e0e3b019... Refs #42128, refactored specs for more test cases
    end

    def any_aptc_ineligible?
      shopping_tax_members.map(&:is_ia_eligible?).include?(false)
    end

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 28e3b77e09... Refs #42128, BenchMark implementation
    def aptc_enrollment_members(aptc_thhms)
      aptc_thhms.select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) && thhm.is_ia_eligible? }
    end

<<<<<<< HEAD
    def enrollment_eligible_benchmark_hash(thhms)
      thhms.inject({}) do |benchmark_hash, thhm|
        benchmark_hash.merge!({ thhm.applicant_id.to_s => thhm.family_member.aptc_benchmark_amount })
      end
    end

    def tax_members_aptc_breakdown(tax_household)
      total_thh_available_aptc = tax_household.total_aptc_available_amount_for_enrollment(@enrollment)
      aptc_thhms = tax_household.aptc_members
      enrolling_aptc_members = aptc_enrollment_members(aptc_thhms)
      member_benchmark_hash = enrollment_eligible_benchmark_hash(enrolling_aptc_members)
      total_eligible_benchmark = member_benchmark_hash.values.sum

      enrolling_aptc_members.inject({}) do |thh_hash, thh_member|
        fm_id = thh_member.applicant_id.to_s
        member_ratio = (member_benchmark_hash[fm_id] / total_eligible_benchmark)
        thh_hash.merge!({ fm_id => (total_thh_available_aptc * member_ratio) })
      end
    end

    def fetch_enrolling_available_aptcs
      aptc_breakdowns = tax_households.inject({}) do |tax_members_aptcs, tax_household|
        aptc_hash = tax_members_aptc_breakdown(tax_household)
        tax_members_aptcs.merge!(aptc_hash) unless aptc_hash.empty?
        tax_members_aptcs
      end

      # If any of the shopping members does not exist in any of
      # the tax households then member is assigned with 0 aptc value
      shopping_member_ids.each do |member_id|
        aptc_breakdowns[member_id] = 0.00 unless aptc_breakdowns.keys.include?(member_id)
      end

      {:aptc => aptc_breakdowns}
=======
    def fetch_aptc
=======
    def fetch_available_aptc
      # TODO: Refactor accordingly once BenchMark code is merged to Base branch
>>>>>>> 52422f4dc1... Refs #42128, ApplicableAptcService setup
      # 1. What if one of the shopping members does not exist in any tax_households
      aptc = tax_households.inject({}) do |aptc_hash, tax_h|
=======
    def tax_members_aptc_breakdown
      tax_households.inject({}) do |aptc_hash, tax_h|
>>>>>>> 7756264eea... Refs #42128, Additional tests added for the Single Tax Household cases
        aptc_hash_thh = tax_h.aptc_available_amount_by_member
        aptc_hash.merge!(aptc_hash_thh) unless aptc_hash_thh.empty?
        aptc_hash
=======
    def enrollment_eligible_benchmark_hash(aptc_thhms)
      aptc_thhms.inject({}) do |benchmark_hash, thhm|
        benchmark_hash.merge!({ thhm.applicant_id.to_s => thhm.family_member.aptc_benchmark_amount })
>>>>>>> 28e3b77e09... Refs #42128, BenchMark implementation
      end
    end

    def tax_members_aptc_breakdown(tax_household)
      total_thh_available_aptc = tax_household.total_aptc_available_amount_for_enrollment(@enrollment)
      aptc_thhms = tax_household.aptc_members
      enrolling_aptc_members = aptc_enrollment_members(aptc_thhms)
      member_aptc_benchmark_hash = enrollment_eligible_benchmark_hash(enrolling_aptc_members)
      total_eligible_member_benchmark = member_aptc_benchmark_hash.values.sum

      enrolling_aptc_members.inject({}) do |thh_hash, thh_member|
        fm_id = thh_member.applicant_id.to_s
        member_ratio = (member_aptc_benchmark_hash[fm_id] / total_eligible_member_benchmark)
        thh_hash.merge!({ fm_id => (total_thh_available_aptc * member_ratio) })
      end
    end

    def fetch_enrolling_available_aptcs
<<<<<<< HEAD
      # 1. What if one of the shopping members does not exist in any tax_households

<<<<<<< HEAD
<<<<<<< HEAD
      {:aptc => final_aptc}
>>>>>>> 20aa6cfd8a... Refs #42128, APTC Service setup
=======
      {:aptc => shopping_member_ids.inject({}) do |required_aptc_hash, member_id|
                  required_aptc_hash.merge!(aptcs_hash.slice(member_id.to_s))
                end}
>>>>>>> 7756264eea... Refs #42128, Additional tests added for the Single Tax Household cases
=======
=======
>>>>>>> 0c442bac29... Refs #42128, Fix for shopping members without associated TaxHouseholdMembers
      aptc_breakdowns = tax_households.inject({}) do |tax_members_aptcs, tax_household|
        aptc_hash = tax_members_aptc_breakdown(tax_household)
        tax_members_aptcs.merge!(aptc_hash) unless aptc_hash.empty?
        tax_members_aptcs
      end

<<<<<<< HEAD
<<<<<<< HEAD
      { :aptc => aptc_breakdowns}
>>>>>>> 28e3b77e09... Refs #42128, BenchMark implementation
=======
=======
      # If any of the shopping members does not exist in any of
      # the tax households then member is assigned with 0 aptc value
      shopping_member_ids.each do |member_id|
        aptc_breakdowns[member_id] = 0.00 unless aptc_breakdowns.keys.include?(member_id)
      end

>>>>>>> 0c442bac29... Refs #42128, Fix for shopping members without associated TaxHouseholdMembers
      {:aptc => aptc_breakdowns}
>>>>>>> 9b0e7f9bc9... Refs #42845, Rounding refactor for storing AppliedAPTC amount on Enrollment
    end

    def prioritized_csr(csr_kinds)
      if csr_kinds.include?('csr_100')
        'csr_100'
      elsif csr_kinds.include?('csr_94')
        'csr_94'
      elsif csr_kinds.include?('csr_87')
        'csr_87'
      elsif csr_kinds.include?('csr_73')
        'csr_73'
      else
        'csr_0'
      end
    end

    def fetch_csr
      return {:csr => 'csr_100'} if (shopping_tax_members.count != shopping_member_ids.count) || any_aptc_ineligible?

      csr_kinds = tax_households.map(&:current_csr_eligibility_kind)
      {:csr => prioritized_csr(csr_kinds)}
    end
  end
end
