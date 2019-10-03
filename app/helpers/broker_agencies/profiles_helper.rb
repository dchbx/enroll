module BrokerAgencies::ProfilesHelper
  def fein_display(broker_agency_profile)
    (broker_agency_profile.organization.is_fake_fein? && !current_user.has_broker_agency_staff_role?)|| (broker_agency_profile.organization.is_fake_fein? && current_user.has_hbx_staff_role?) || !broker_agency_profile.organization.is_fake_fein?
  end

  def get_commission_statements_for_year(statements, year)
    results = []
    statements.each do |statement|
      if statement.date.year == year.to_i
        results << statement
      end
    end
    results
  end

  def commission_statement_formatted_date(date)
    date.strftime("%m/%d/%Y")
  end

  def commission_statement_coverage_period(date)
    "#{date.prev_month.beginning_of_month.strftime('%b %Y')}" rescue nil
  end

  def can_show_destroy?(current_user, staff)
    return true if current_user.person == staff || staff.broker_role.present? || staff.general_agency_primary_staff.present?
  end

  def disable_edit_broker_agency?(user)
    return false if user.has_hbx_staff_role?
    person = user.person
    person.broker_role.present? ? false : true
  end

  def disable_edit_general_agency?(user)
    return false if user.has_hbx_staff_role?
    person = user.person
    person.general_agency_primary_staff.present? ? false : true
  end
end
