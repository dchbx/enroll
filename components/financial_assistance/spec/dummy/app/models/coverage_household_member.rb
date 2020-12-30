# frozen_string_literal: true

class CoverageHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :coverage_household

  field :family_member_id, type: BSON::ObjectId
  field :is_subscriber, type: Boolean, default: false

  # def save_parent
  #   coverage_household.save
  # end

  include BelongsToFamilyMember

  def family
    coverage_household.household.family
  end

  def family_member=(new_family_member)
    self.family_member_id = new_family_member._id
    @family_member = new_family_member
  end

  def family_member
    return @family_member if defined? @family_member
    @family_member = family.family_members.find(family_member_id) if family_member_id.present?
  end

  attr_writer :applicant

  def applicant
    return @applicant if defined? @applicant
    @applicant = family_member
  end

  def is_subscriber?
    self.is_subscriber
  end

end
