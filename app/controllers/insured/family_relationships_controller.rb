class Insured::FamilyRelationshipsController < ApplicationController
	before_action :set_current_person, :set_family

	def index
    if (params[:resident_role_id].present? && params[:resident_role_id])
      @type = "resident"
      @resident_role = @person.resident_role
      @family.hire_broker_agency(current_user.person.broker_role.try(:id))
    end

    if params[:employee_role_id].present? && params[:employee_role_id]
      @type = "employee"
      emp_role_id = params.require(:employee_role_id)
      @employee_role = @person.employee_roles.detect { |emp_role| emp_role.id.to_s == emp_role_id.to_s }
    elsif params[:consumer_role_id].present? && params[:consumer_role_id]
      @type = "consumer"
      @consumer_role = @person.consumer_role
      @family.hire_broker_agency(current_user.person.broker_role.try(:id))
    end
    @change_plan = params[:change_plan].present? ? 'change_by_qle' : ''
    @change_plan_date = params[:qle_date].present? ? params[:qle_date] : ''
    @application = @family.application_in_progress
    @people = @family.family_members.where(is_active: true).map(&:person)
    @matrix = @family.build_relationship_matrix
    @missing_relationships = @family.find_missing_relationships(@matrix)
    # @existing_relationships = @family.find_existing_relationships(@matrix)
    @all_relationships = @family.find_all_relationships(@matrix)
    @relationship_kinds = PersonRelationship::Relationships_UI

    render layout: 'financial_assistance'
  end

  def create
    @application = @family.application_in_progress

    predecessor = Person.where(id: params[:predecessor_id]).first
    successor = Person.where(id: params[:successor_id]).first
    predecessor.add_relationship(successor, params[:kind], @family.id, true)
    successor.add_relationship(predecessor, PersonRelationship::InverseMap[params[:kind]], @family.id)
    @family.reload
    @matrix = @family.build_relationship_matrix
    @missing_relationships = @family.find_missing_relationships(@matrix)
    @relationship_kinds = PersonRelationship::Relationships_UI
    @people = @family.family_members.where(is_active: true).map(&:person)
    @all_relationships = @family.find_all_relationships(@matrix)

    respond_to do |format|
      format.html {
        redirect_to insured_family_relationships_path(employee_role_id: params[:employee_role_id], consumer_role_id: params[:consumer_role_id], resident_role_id: params[:resident_role_id]), notice: 'Relationship was successfully updated.'
      }
      format.js
    end
  end

  private
  def set_family
    @family = @person.try(:primary_family)
  end
end