class Admin::Aptc < ApplicationController

  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  $months_array = Date::ABBR_MONTHNAMES.compact

  class << self

    def build_household_level_aptc_csr_data(year, family, hbxs=nil, max_aptc=nil, csr_percentage=nil, applied_aptc_array=nil,  member_ids=nil)
      max_aptc_vals             = build_max_aptc_values(year, family, max_aptc, hbxs)
      csr_percentage_vals       = build_csr_percentage_values(year, family, csr_percentage)
      avalaible_aptc_vals       = build_avalaible_aptc_values(year, family, hbxs, applied_aptc_array, max_aptc, member_ids)
      return { "max_aptc" => max_aptc_vals, "available_aptc" => avalaible_aptc_vals, "csr_percentage" => csr_percentage_vals}
    end

    def build_avalaible_aptc_values(year, family, hbxs, applied_aptc_array=nil, max_aptc=nil,  member_ids=nil)
      available_aptc_hash = Hash.new
      #max_aptc_vals             = build_max_aptc_values(family, max_aptc)
      max_aptc_vals             = build_max_aptc_values(year, family, max_aptc, hbxs)
      total_aptc_applied_vals_for_household = Hash[$months_array.map { |x| [x, '%.2f' % 0.0] }] # Initialize a Hash for monthly values.
      hbxs.each do |hbx|
        aptc_applied_vals_for_enrollment = build_aptc_applied_values_for_enrollment(year, family, hbx, applied_aptc_array)
        total_aptc_applied_vals_for_household  = total_aptc_applied_vals_for_household.merge(aptc_applied_vals_for_enrollment) { |k, a_value, b_value| a_value.to_f + b_value.to_f } # Adding values of two similar hashes.
      end
      #subtract each value of aptc_applied hash from the max_aptc hash to get APTC Available.
      max_aptc_vals.merge(total_aptc_applied_vals_for_household) { |k, a_value, b_value| '%.2f' % (a_value.to_f >= b_value.to_f ? (a_value.to_f - b_value.to_f) : a_value.to_f - b_value.to_f) }
    end

    # def negative_aptc(k, a_value, b_value, total_aptc_applied_vals_for_household, hbxs)
    #   a_value - b_value
    # end

    def build_household_members(year, family, max_aptc=nil)
      individuals_covered_array = Array.new
      max_aptc = max_aptc.present? ? max_aptc.to_f : (family.active_household.latest_active_tax_household_with_year(year).latest_eligibility_determination.max_aptc.to_f rescue 0)
      ratio_by_member = family.active_household.latest_active_tax_household_with_year(year).try(:aptc_ratio_by_member)
      family.family_members.each_with_index do |one_member, index|
        individuals_covered_array << {one_member.person.id.to_s => [ratio_by_member[one_member.id.to_s] * max_aptc, max_aptc]}  rescue nil # Individuals and their assigned APTC Ratio
      end
      return individuals_covered_array
    end

    def build_enrollments_data(year, family, hbxs, applied_aptc_array=nil, max_aptc=nil, csr_percentage=nil, member_ids=nil)
      enrollments_data = Hash.new
      hbxs.each do |hbx|
        enrollments_data[hbx.id] = self.build_enrollment_level_aptc_csr_data(year, family, hbx, applied_aptc_array, max_aptc, csr_percentage)
      end
      return enrollments_data
    end

    def build_enrollment_level_aptc_csr_data(year, family, hbx, applied_aptc_array=nil, max_aptc=nil, csr_percentage=nil,  member_ids=nil) #TODO: Last param remove
      aptc_applied_vals             = build_aptc_applied_values_for_enrollment(year, family, hbx, applied_aptc_array)
      aptc_applied_per_member_vals  = build_aptc_applied_per_member_values_for_enrollment(family, hbx, aptc_applied_vals, applied_aptc_array)
      return { "aptc_applied" => aptc_applied_vals, "aptc_applied_per_member" => aptc_applied_per_member_vals }
    end

    def build_plan_premium_hash_for_enrollments(hbxs)
      plan_premium_hash = Hash.new
      hbxs.each do |hbx|
        plan_premium_hash[hbx.id.to_s] = (hbx.try(:total_premium) || false)
      end
      return plan_premium_hash
    end


    def build_aptc_applied_values_for_enrollment(year, family, current_hbx, applied_aptc_array=nil)
      # Get all aptc enrollments (coverage selected, terminated or cancelled) that have the same hbx_id as current_hbx.
      # These are the dups of the current enrollment that were saved when APTC values were updated.
      enrollments_with_same_hbx_id = family.active_household.hbx_enrollments_with_aptc_by_year(year).by_hbx_id(current_hbx.hbx_id)
      enrollments_with_same_hbx_id.sort! {|a, b| a.effective_on <=> b.effective_on}
      aptc_applied_hash = Hash.new
      $months_array.each_with_index do |month, ind|
        enrollments_with_same_hbx_id.each do |hbx_iter|
          update_aptc_applied_hash_for_month(year, aptc_applied_hash, current_hbx, month, hbx_iter, family, applied_aptc_array)
        end
      end
      return aptc_applied_hash
    end

    def update_aptc_applied_hash_for_month(year, aptc_applied_hash, current_hbx, month, hbx_iter, family, applied_aptc_array=nil)
      first_of_month_num_current_year = last_of_month_converter(month, year)
      applied_aptc = 0.0
      if applied_aptc_array.present?
        #if first_of_month_num_current_year >= TimeKeeper.datetime_of_record
        if first_of_month_num_current_year >= find_enrollment_effective_on_date(TimeKeeper.datetime_of_record).to_date # Following the 15 day rule for calculations
          applied_aptc_array.each do |one_hbx|
            applied_aptc = one_hbx[1]["aptc_applied"].to_f if current_hbx.id.to_s == one_hbx[1]["hbx_id"].gsub("aptc_applied_","")
          end
        else
          applied_aptc = hbx_iter.applied_aptc_amount.to_f
        end
      else
        applied_aptc = hbx_iter.applied_aptc_amount.to_f
      end

      first_of_month_num_current_year = last_of_month_converter(month, year)
      if first_of_month_num_current_year >= hbx_iter.effective_on.to_date
        aptc_applied_hash.store(month, '%.2f' % applied_aptc)
      else
        aptc_applied_hash.store(month, '%.2f' % 0.00) if aptc_applied_hash[month].blank? #dont mess with the past values
      end
    end

    def build_aptc_applied_per_member_values_for_enrollment(family, current_hbx, aptc_applied_vals, applied_aptc_array=nil)
      aptc_applied_per_member = Hash.new
      percent_sum = 0.0
      aptc_ratio_by_member = family.active_household.latest_active_tax_household.aptc_ratio_by_member

      current_hbx.hbx_enrollment_members.each do |member|
        percent_sum += family.active_household.latest_active_tax_household.aptc_ratio_by_member[member.applicant_id.to_s] || 0.0
      end

      current_hbx.hbx_enrollment_members.each do |hem|
        ratio_for_this_member = aptc_ratio_by_member[hem.applicant_id.to_s]
        aptc_applied_member_vals = aptc_applied_vals.inject({}) { |h, (k, v)| h[k] = '%.2f' % (v.to_f * ratio_for_this_member.to_f / percent_sum.to_f); h }
        aptc_applied_per_member[hem.person.id.to_s] =  aptc_applied_member_vals
      end
      aptc_applied_per_member
    end


    def build_max_aptc_values(year, family, max_aptc=nil, hbxs=nil)
      max_aptc_hash = Hash.new
      #eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      eligibility_determinations = family.active_household.eligibility_determinations_for_year(year)
      eligibility_determinations.sort! {|a, b| a.determined_at <=> b.determined_at}
      #ed = family.active_household.latest_tax_household_with_year(year).latest_eligibility_determination
      $months_array.each_with_index do |month, ind|
        # iterate over all the EligibilityDeterminations and store the correct max_aptc value for each month. Account for any monthly change in Eligibility Determination.
        eligibility_determinations.each do |ed|
          update_max_aptc_hash_for_month(max_aptc_hash, year, month, ed, max_aptc, hbxs)
          #if month == "Jul" || month == "Aug" || month == "Sep"
        end
      end
      return max_aptc_hash
    end

    def update_max_aptc_hash_for_month(max_aptc_hash, year, month, ed, max_aptc=nil, hbxs=nil)
      first_of_month_num_current_year = last_of_month_converter(month, year)
      max_aptc_value = ""
      if max_aptc.present?
        effective_starting_on = ed.tax_household.effective_starting_on
        if effective_starting_on > TimeKeeper.date_of_record
          max_aptc_value = first_of_month_num_current_year >= TimeKeeper.datetime_of_record ? max_aptc : ed.max_aptc.to_f  if hbxs.blank?
          max_aptc_value = first_of_month_num_current_year >= effective_starting_on ? max_aptc : ed.max_aptc.to_f  if hbxs.present? # Incase there are active enrollments, follow 15th of the month rule.
        else
          max_aptc_value = first_of_month_num_current_year >= TimeKeeper.datetime_of_record ? max_aptc : ed.max_aptc.to_f  if hbxs.blank?
          max_aptc_value = first_of_month_num_current_year >= find_enrollment_effective_on_date(TimeKeeper.datetime_of_record).to_date ? max_aptc : ed.max_aptc.to_f  if hbxs.present? # Incase there are active enrollments, follow 15th of the month rule.
        end
      else
        max_aptc_value = ed.max_aptc.to_f
      end
      # Check if  'month' >= EligibilityDetermination.determined_at date?
      if first_of_month_num_current_year >= ed.determined_at.to_date
        # assign that month with aptc_max value from this ed (EligibilityDetermination)
        max_aptc_hash.store(month, '%.2f' % max_aptc_value)
      else
        # update max_aptc value for that month as a "---"
        max_aptc_hash.store(month, '%.2f' % 0) if max_aptc_hash[month].blank?
      end
    end

    def build_csr_percentage_values(year, family, csr_percentage=nil)
      csr_percentage_hash = Hash.new
      #eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      eligibility_determinations = family.active_household.eligibility_determinations_for_year(year)
      eligibility_determinations.sort! {|a, b| a.determined_at <=> b.determined_at}
      #ed = family.active_household.latest_tax_household_with_year(year).latest_eligibility_determination
      $months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|
          update_csr_percentages_hash_for_month(csr_percentage_hash, year, month, ed, csr_percentage)
        end
      end
      return csr_percentage_hash
    end

    def update_csr_percentages_hash_for_month(csr_percentage_hash, year, month, ed, csr_percentage=nil)
      first_of_month_num_current_year = last_of_month_converter(month, year)
      csr_percentage_value = ""
      #csr_percentage_value = csr_percentage.present? ? csr_percentage : ed.csr_percent_as_integer
      if csr_percentage.present?
        # this is when we check available aptc. We only want to update the current and future fields with the updated value.
        if first_of_month_num_current_year >= TimeKeeper.datetime_of_record
          csr_percentage_value = csr_percentage
        else
          # leave past values as-is
          csr_percentage_value = ed.csr_percent_as_integer
        end
      else
        csr_percentage_value = ed.csr_percent_as_integer == -1 ? "limited" : ed.csr_percent_as_integer
      end
      # Check if  'month' >= EligibilityDetermination.determined_at date?
      if first_of_month_num_current_year >= ed.determined_at.to_date
        # assign that month with csr_percent value from this ed (EligibilityDetermination)
        csr_percentage_hash.store(month, csr_percentage_value)
      else
        # update csr_percent value for that month as a "-"
        csr_percentage_hash.store(month, 0) if csr_percentage_hash[month].blank?
      end
    end

    def last_of_month_converter(month, year=TimeKeeper.date_of_record.year)
      month_num = Date::ABBR_MONTHNAMES.index(month.capitalize || month) # coverts Month name to Month Integer : "jan" -> 1
      last_day = Time.days_in_month(month_num, year)
      last_of_month_date = Date.parse("#{year}-#{month_num}-#{last_day}")
      return last_of_month_date
    end


    def calculate_slcsp_value(year, family, member_ids=nil)
      benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
      #eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      #date = Date.new(year, 1, 1)
      benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}
      slcsp = benefit_coverage_period.second_lowest_cost_silver_plan
      if member_ids.present?
        aptc_members = family.active_household.latest_active_tax_household.tax_household_members.select {|m| member_ids.include?(m.person.id.to_s) }
      else
        aptc_members = family.active_household.latest_active_tax_household.aptc_members
      end
      cost = aptc_members.map do |member|
        slcsp.premium_for(TimeKeeper.datetime_of_record, member.age_on_effective_date)
      end.inject(:+) || 0
      return '%.2f' % cost
    end


    def build_eligible_members(family, member_ids=nil)
      return member_ids if member_ids.present?
      eligible_members = Array.new
      tax_household_members = family.active_household.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year).try(:tax_household_members)
      return [] if tax_household_members.nil?
      tax_household_members.each do |member|
        if member.is_ia_eligible
          eligible_members << member.person.id.to_s
        end
      end
      return eligible_members
    end


    def build_aptc_per_enrollment(hbxs)
      aptc_per_enrollment = Hash.new
      hbxs.each do |hbx|
        plan_name         = Plan.where(id: hbx.plan_id).first.name
        hbx_applied_aptc  = hbx.applied_aptc_amount.to_f
        aptc_per_enrollment[hbx.id.to_s] = [hbx_applied_aptc, plan_name]
      end
      aptc_per_enrollment
    end


    def build_current_aptc_applied_hash(hbxs, applied_aptcs_array=nil)
      current_aptc_applied_hash = Hash.new
      hbxs.each do |hbx|
        if applied_aptcs_array.present?
          applied_aptcs_array.each do |app_aptc|
            current_aptc_applied_hash[hbx.id.to_s] =  '%.2f' % app_aptc[1]["aptc_applied"].to_f if hbx.id.to_s == app_aptc[1]["hbx_id"].gsub("aptc_applied_","")
          end
        else
          current_aptc_applied_hash[hbx.id.to_s] = (hbx.applied_aptc_amount || 0)
        end
      end
      return current_aptc_applied_hash
    end

    # Redetermine Eligibility on Max APTC / CSR Update.
    def redetermine_eligibility_with_updated_values(family, params, hbxs, year)
      eligibility_redetermination_result = false
      latest_eligibility_determination = family.active_household.latest_active_tax_household_with_year(year).latest_eligibility_determination
      max_aptc = latest_eligibility_determination.max_aptc
      csr_percent_as_integer = latest_eligibility_determination.csr_percent_as_integer
      csr_percentage_param = params[:csr_percentage] == "limited" ? -1 : params[:csr_percentage].to_i # storing "limited" CSR as -1

      if !(params[:max_aptc].to_f == max_aptc && csr_percentage_param == csr_percent_as_integer) # If any changes made to MAX APTC or CSR
        effective_starting_on = family.active_household.latest_active_tax_household_with_year(year).effective_starting_on
        if effective_starting_on > TimeKeeper.date_of_record
          eligibility_date = effective_starting_on
        else
          eligibility_date = hbxs.present? ? find_enrollment_effective_on_date(TimeKeeper.datetime_of_record) : TimeKeeper.datetime_of_record # Follow 15th of month rule if active enrollment.
        end
        # If max_aptc / csr percent is updated, create a new eligibility_determination with a new "determined_at" timestamp and the corresponsing csr/aptc update.
        tax_household = family.active_household.latest_active_tax_household_with_year(year)
        tax_household.eligibility_determinations.build({"determined_at"                 => eligibility_date,
                                                        "determined_on"                 => eligibility_date,
                                                        "csr_eligibility_kind"          => latest_eligibility_determination.csr_eligibility_kind,
                                                        "premium_credit_strategy_kind"  => latest_eligibility_determination.premium_credit_strategy_kind,
                                                        "csr_percent_as_integer"        => csr_percentage_param,
                                                        "max_aptc"                      => params[:max_aptc].to_f,
                                                        "benchmark_plan_id"             => latest_eligibility_determination.benchmark_plan_id,
                                                        "e_pdc_id"                      => latest_eligibility_determination.e_pdc_id,
                                                        "source"                        => "Admin"
                                                       }).save!
        eligibility_redetermination_result = true
      end
      eligibility_redetermination_result
    end

    # Create new Enrollments when Applied APTC for an Enrollment is Updated.
    def update_aptc_applied_for_enrollments(family, params, year)
      current_datetime = TimeKeeper.datetime_of_record
      enrollment_update_result = false
      # For every HbxEnrollment, if Applied APTC was updated, clone a new enrtollment with the new Applied APTC and make the current one inactive.
      #family = Family.find(params[:person][:family_id])
      max_aptc = family.active_household.latest_active_tax_household_with_year(year).latest_eligibility_determination.max_aptc.to_f
      active_aptc_hbxs = family.active_household.hbx_enrollments_with_aptc_by_year(params[:year].to_i)

      params.each do |key, aptc_value|
        if key.include?('aptc_applied_')
          # TODO enrollment duplication has to be refactored once Ram promotes reusable module to create HbxEnrollment copy
          hbx_id = key.sub("aptc_applied_", "")
          updated_aptc_value = aptc_value.to_f
          actual_aptc_value = HbxEnrollment.find(hbx_id).applied_aptc_amount.to_f
          # Only create enrollments if the APTC values were updated.
          if actual_aptc_value != updated_aptc_value # TODO: check if the effective_on doesnt go to next year?????
            percent_sum_for_all_enrolles = 0.0
            enrollment_update_result = true
            original_hbx = HbxEnrollment.find(hbx_id)
            aptc_ratio_by_member = family.active_household.latest_active_tax_household.aptc_ratio_by_member

            # Duplicate Enrollment
            duplicate_hbx = original_hbx.dup

            # Update the following fields
            duplicate_hbx.created_at = current_datetime
            duplicate_hbx.updated_at = current_datetime
            duplicate_hbx.effective_on = find_enrollment_effective_on_date(current_datetime).to_date # Populate the effective_on date based on the 15th day rule.
            duplicate_hbx.hbx_id = HbxIdGenerator.generate_policy_id

            # Duplicate all Enrollment Members
            duplicate_hbx.hbx_enrollment_members = original_hbx.hbx_enrollment_members.collect {|hem| hem.dup}
            duplicate_hbx.hbx_enrollment_members.each{|hem| hem.updated_at = current_datetime}

            # Update Applied APTC on the enrolllment level.
            duplicate_hbx.applied_aptc_amount = updated_aptc_value

            # Update elected_aptc_pct to the correct value based on the new applied_amount
            duplicate_hbx.elected_aptc_pct = actual_aptc_value/max_aptc

            # Reset aasm_state
            duplicate_hbx.aasm_state = "shopping"

            # This (and the division using percent_sum_for_all_enrolles in the next block) is needed to get the right ratio for members to use in an enrollment. (ratio of the applied_aptc for an enrollment)
            duplicate_hbx.hbx_enrollment_members.each do |member|
              percent_sum_for_all_enrolles += family.active_household.latest_active_tax_household.aptc_ratio_by_member[member.applicant_id.to_s] || 0.0
            end

            # Update the correct breakdown of Applied APTC on the individual level.
            duplicate_hbx.hbx_enrollment_members.each do |hem|
              aptc_pct_for_member = aptc_ratio_by_member[hem.applicant_id.to_s] || 0.0
              hem.applied_aptc_amount = updated_aptc_value * aptc_pct_for_member / percent_sum_for_all_enrolles
            end

            family.active_household.hbx_enrollments << duplicate_hbx
            family.save

            # Reload and Select Coverage for new Enrollment. This ensures workflow transition is set
            duplicate_hbx.reload
            duplicate_hbx.select_coverage!


            # Cancel or Terminate Coverage.
            if original_hbx.may_terminate_coverage? && (duplicate_hbx.effective_on > original_hbx.effective_on)
              original_hbx.terminate_coverage!
              original_hbx.update_current(terminated_on: duplicate_hbx.effective_on - 1.day)
            else
              original_hbx.cancel_coverage! if original_hbx.may_cancel_coverage?
            end
          end

        end
      end
      enrollment_update_result
    end

    # 15th of the month rule
    def find_enrollment_effective_on_date(hbx_created_datetime)
      offset_month = hbx_created_datetime.day <= 15 ? 1 : 2
      year = hbx_created_datetime.year
      month = hbx_created_datetime.month + offset_month
      # Based on the 15th of the month rule, if the effective date happpens to be after the policy's life (next year),
      # raise an error and do not create a new EligibilityDetermination (when there is an active enrollment) and/or HbxEnrollment (Eg: After Nov 15th)
      if month > 12
        year = year + 1
        month = month - 12
      end
      day = 1
      hour = hbx_created_datetime.hour
      min = hbx_created_datetime.min
      sec = hbx_created_datetime.sec
      return DateTime.new(year, month, day, hour, min, sec)
      #return DateTime.new(year, month, day)
    end

    def build_error_messages(max_aptc, csr_percentage, applied_aptcs_array, year, hbxs)
      sum_of_all_applied = 0.0
      aptc_errors = Hash.new
      if hbxs.present? && find_enrollment_effective_on_date(TimeKeeper.datetime_of_record).year != year
        aptc_errors["EFFECTIVE_DATE_OVERFLOW"] = Settings.aptc_errors.effective_date_overflow
      end

      if applied_aptcs_array.present?
        applied_aptcs_array.each do |hbx|
          max_for_hbx = max_aptc_that_can_be_applied_for_this_enrollment(hbx[1]["hbx_id"].gsub("aptc_applied_",""), max_aptc)
          applied_aptc = hbx[1]["aptc_applied"].to_f
          aptc_errors["ENROLLMENT_MAX_SMALLER_THAN_APPLIED"] = Settings.aptc_errors.enrollment_max_smaller_than_applied + "[NEW_MAX_FOR_ENROLLMENT (#{'%.2f' % max_for_hbx.to_s}) < APPLIED_APTC (#{'%.2f' % applied_aptc.to_s})] " if applied_aptc > max_for_hbx
          hbx_enrollment = hbxs.select{|h| h.id.to_s == hbx[1]["hbx_id"].gsub("aptc_applied_","") }.first
          plan_premium = hbx_enrollment.total_premium
          aptc_errors["PREMIUM_SMALLER_THAN_APPLIED"] = Settings.aptc_errors.plan_premium_smaller_than_applied + "[PLAN_PREMIUM (#{'%.2f' % plan_premium.to_s}) < APPLIED_APTC (#{'%.2f' % applied_aptc.to_s})] " if applied_aptc > plan_premium
          sum_of_all_applied += hbx[1]["aptc_applied"].to_f
        end
      end
      #applied_aptcs_array.each {|hbx|  if applied_aptcs_array.present?

      if max_aptc == "NaN"
        aptc_errors["MAX_APTC_NON_NUMERIC"] = Settings.aptc_errors.max_aptc_non_numeric
      elsif applied_aptcs_array.present? && sum_of_all_applied.to_f > max_aptc.to_f
        aptc_errors["MAX_APTC_TOO_SMALL"] = Settings.aptc_errors.max_aptc_too_small
      elsif max_aptc.to_f > 9999.99
        aptc_errors["MAX_APTC_TOO_BIG"]  = Settings.aptc_errors.max_aptc_too_big
      end
      return aptc_errors
    end

    def max_aptc_that_can_be_applied_for_this_enrollment(hbx_id, max_aptc_for_household)
      #1 Get all members in the enrollment
      #2 Get APTC ratio for each of these members
      #3 Max APTC for Enrollment => Sum all (ratio * max_aptc) for each members
      max_aptc_for_enrollment = 0
      hbx = HbxEnrollment.find(hbx_id)
      hbx_enrollment_members = hbx.hbx_enrollment_members
      aptc_ratio_by_member = hbx.family.active_household.latest_active_tax_household.aptc_ratio_by_member
      hbx_enrollment_members.each do |hem|
        max_aptc_for_enrollment += (aptc_ratio_by_member[hem.applicant_id.to_s].to_f * max_aptc_for_household.to_f)
      end
      if max_aptc_for_enrollment > max_aptc_for_household.to_f
        max_aptc_for_household.to_f
      else
        max_aptc_for_enrollment.to_f
      end
    end

    def years_with_tax_household(family)
      year_set = family.active_household.tax_households.map(&:effective_starting_on).map(&:year)
      current_hbx = HbxProfile.current_hbx
      oe_start_year = Settings.aca.individual_market.open_enrollment.start_on.year
      current_year = TimeKeeper.date_of_record.year

      if current_hbx && current_hbx.under_open_enrollment? && oe_start_year == current_year
        year_set << (TimeKeeper.date_of_record.next_year.year)
      end

      year_set.uniq
    end

  end #  end of class << self
end # end of class HbxAdmin
