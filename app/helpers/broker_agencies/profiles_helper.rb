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

end
