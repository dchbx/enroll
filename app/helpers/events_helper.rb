module EventsHelper
  def xml_iso8601_for(date_time)
    return nil if date_time.blank?
    date_time.iso8601
  end

  def simple_date_for(date_time)
    return nil if date_time.blank?
    date_time.strftime("%Y%m%d")
  end

  def vocab_relationship_map(rel)
    rel.gsub(" ", "_")
  end

  def xml_eligibility_event_uri(eligibility_event)
    eligibility_kind = eligibility_event.eligibility_event_kind
    event_uri = case eligibility_kind
                when "relocate"
                  "location_change"
                when "eligibility_change_immigration_status"
                  "citizen_status_change"
                when "lost_hardship_exemption"
                  "eligibility_change_assistance"
                when "eligibility_change_income"
                  "eligibility_change_assistance"
                when "court_order"
                  "medical_coverage_order"
                when "domestic_partnership"
                  "entering_domestic_partnership"
                when "new_eligibility_member"
                  "drop_family_member_due_to_new_eligibility"
                when "new_eligibility_family"
                  "drop_family_member_due_to_new_eligibility"
                when "employer_sponsored_coverage_termination"
                  "eligibility_change_employer_ineligible"
                when "employer_sponsored_cobra"
                  "cobra"
                else
                  eligibility_kind
                end
    "urn:dc0:terms:v1:qualifying_life_event##{event_uri}"
  end

  def office_location_address_kind(kind)
    if kind == "primary"
      "work"
    elsif kind == "branch"
      "work"
    else
      kind
    end
  end

  def is_office_location_address_valid?(office_location)
    office_location.present? && office_location.address.present? && (['mailing', 'work', 'primary'].include? office_location.address.kind)
  end

  def is_office_location_phone_valid?(office_location)
    office_location.present? && office_location.phone.present? && ((['work', 'home', 'main'].include? office_location.phone.kind) || (office_location.phone.kind == 'phone main'))
    #Adding phone kind 'phone main' temporary, revert once phone.kind in office location fixed.
  end

  def transaction_id
    @transaction_id ||= begin
                          ran = Random.new
                          current_time = Time.now.utc
                          reference_number_base = current_time.strftime("%Y%m%d%H%M%S") + current_time.usec.to_s[0..2]
                          reference_number_base + sprintf("%05i",ran.rand(65535))
                        end
  end

  def employer_plan_years(employer)
    employer.plan_years.select(&:eligible_for_export?)
  end

  def is_initial_or_conversion_employer?(employer)
    (employer.published_plan_year.present? && employer.renewing_published_plan_year.blank?) && (!employer.is_conversion? || (employer.is_conversion? && !employer.published_plan_year.is_conversion))
  end

  def is_renewal_employer?(employer)
    employer.published_plan_year.present? && employer.renewing_published_plan_year.present? && !employer.is_conversion?
  end

  def is_renewing_conversion_employer?(employer)
    employer.is_conversion? && employer.published_plan_year.present? && !employer.published_plan_year.is_conversion && employer.renewing_published_plan_year.present?
  end

  def is_new_conversion_employer?(employer)
    employer.is_conversion? && employer.active_plan_year.present? && employer.active_plan_year.is_conversion && employer.renewing_published_plan_year.present?
  end

  def is_renewal_or_conversion_employer?(employer)
    is_new_conversion_employer?(employer) || is_renewal_employer?(employer) || is_renewing_conversion_employer?(employer)
  end
end
