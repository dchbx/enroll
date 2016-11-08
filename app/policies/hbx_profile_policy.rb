class HbxProfilePolicy < ApplicationPolicy

  def view_admin_tabs?
    return true unless role = user.person.hbx_staff_role
    role.permission.view_admin_tabs
  end

  def modify_admin_tabs?
    return true unless role = user.person.hbx_staff_role
    role.permission.modify_admin_tabs
  end

  def send_broker_agency_message?
    return true unless role = user.person.hbx_staff_role
    role.permission.send_broker_agency_message
  end

  def approve_broker?
    return true unless role = user.person.hbx_staff_role
    role.permission.approve_broker
  end

  def approve_ga?
    return true unless role = user.person.hbx_staff_role
    role.permission.approve_ga
  end

  def show?
    @user.has_role?(:hbx_staff) or
      @user.has_role?(:csr) or
      @user.has_role?(:assister)
  end

  def index?
    @user.has_role? :hbx_staff
  end

  def employer_index?
    index?
  end

  def family_index?
    index?
  end

  def broker_agency_index?
    index?
  end

  def issuer_index?
    index?
  end

  def product_index?
    index?
  end

  def configuration?
    index?
  end

  def new?
    @user.has_role? :hbx_staff
  end

  def edit?
    if @user.has_role?(:hbx_staff)
      @record.id == @user.try(:person).try(:hbx_staff_role).try(:hbx_profile).try(:id)
    else
      false
    end
  end

  def inbox?
    index?
  end

  def create?
    new?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def set_date?
    index?
  end
end
