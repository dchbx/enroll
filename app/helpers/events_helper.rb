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

  def office_location_address_kind(kind)
    if kind == "primary"
      "work"
    elsif kind == "branch"
      "work"
    else
      kind
    end
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
    if (is_renewal_or_conversion_employer?(employer) && TimeKeeper.date_of_record >= ((employer.renewing_published_plan_year.start_on - 1.month)+15.days))  || (is_initial_employer?(employer) && TimeKeeper.date_of_record >= ((employer.published_plan_year.start_on - 1.month)+15.days))
      employer.plan_years.select(&:eligible_for_export?)
    elsif (!employer.is_conversion? && employer.renewing_published_plan_year.present?)
      employer.active_plan_year.to_a
    end
  end

  def is_initial_employer?(employer)
    employer.published_plan_year.present? && employer.renewing_published_plan_year.blank?
  end

  def is_renewal_or_conversion_employer?(employer)
    employer.published_plan_year.present? && employer.renewing_published_plan_year.present?
  end
end
