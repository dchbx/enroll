# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    read_all?
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    update_all?
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def read_all?
    @user.has_role?(:employer_staff) ||
      @user.has_role?(:employee) ||
      @user.has_role?(:broker) ||
      @user.has_role?(:broker_agency_staff) ||
      @user.has_role?(:consumer) ||
      @user.has_role?(:resident) ||
      @user.has_role?(:hbx_staff) ||
      @user.has_role?(:system_service) ||
      @user.has_role?(:web_service) ||
      @user.has_role?(:assister) ||
      @user.has_role?(:csr)
  end

  def update_all?
    @user.has_role?(:broker_agency_staff) ||
      @user.has_role?(:assister) ||
      @user.has_role?(:csr)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
