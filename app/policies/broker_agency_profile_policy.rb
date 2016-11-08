class BrokerAgencyProfilePolicy < ApplicationPolicy
  def access_to_broker_agency_profile?
    return false unless user.person
    return true if user.person.hbx_staff_role
    bap_id = record.id
    broker_role = user.person.broker_role
    if broker_role
      return true if broker_role.broker_agency_profile_id == bap_id && broker_role.active?
    end
    staff_roles = user.person.broker_agency_staff_roles || []
    staff_roles.any?{|r| r.broker_agency_profile_id == bap_id && r.active?}
  end
end

