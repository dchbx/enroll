module Employers::BrokerAgencyHelper
  def assignment_date(employer_profile)
    employer_profile.active_broker_agency_account.start_on if employer_profile.active_broker_agency_account.present?
  end
end
