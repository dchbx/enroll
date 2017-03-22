module Employers::BrokerAgencyHelper
  def assignment_date(employer_profile)
    employer_profile.active_broker_agency_account.created_at if employer_profile.active_broker_agency_account.present?
  end
end
