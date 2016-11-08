class CensusEmployeePolicy < ApplicationPolicy
#TODOJF JULY 1 review this 
  def update?
    if @user.has_role? :hbx_staff
      true
    else
      can_change = if @user.has_role? :employer_staff
                     @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include? @record.employer_profile_id.try(:to_s) rescue false
                   elsif @user.has_role? :broker
                     @record.employer_profile.try(:active_broker) == @user.person
                   else
                     false
                   end
      can_change || (!@record.dob_changed? && !@record.ssn_changed?)
    end
  end

  def delink?
    if @user.has_role? :hbx_staff or
       @user.has_role? :broker_agency_staff or
       @user.has_role? :broker
      @record.employee_role_linked?
    else
      false
    end
  end
end
