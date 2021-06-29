# frozen_string_literal: true

module BelongsToFamilyMember
  def family_member
    return nil unless family
    family.family_members.detect { |apl| applicant_id == apl._id }
  end

  def family_member=(applicant_instance)
    return unless applicant_instance.is_a? FamilyMember
    self.applicant_id = applicant_instance._id
  end
end
