class ResidentRolePolicy < ApplicationPolicy
  def privacy?
    if @user.has_role? :hbx_staff
      true
    end  
  end

  def search?
    privacy?
  end

  def match?
    privacy?
  end

  def create?
    privacy?
  end

  def ridp_agreement?
    privacy?
  end

  def edit?
    privacy?
  end

  def update?
    edit?
  end
end
