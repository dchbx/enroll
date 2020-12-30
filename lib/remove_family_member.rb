module RemoveFamilyMember
  def set_instance_variables(family, bson_id)
    @family_member = family.family_members.find(bson_id)
    @duplicate_fms = family.family_members.where(person_id: @family_member.person.id)
    @chm_fm_ids = family.active_household.coverage_households.flat_map(&:coverage_household_members).map(&:family_member_id)
    @hbx_member_fm_ids = family.active_household.hbx_enrollments.flat_map(&:hbx_enrollment_members).map(&:applicant_id)
    @th_member_ids = family.active_household.tax_households.flat_map(&:tax_household_members).map(&:applicant_id)
  end

  def fetch_dependency_type(bson_id)
    dup_fms_exists = @duplicate_fms.count > 1
    dup_chms_exists = @chm_fm_ids.include?(bson_id)
    dup_hbx_members_exists = @hbx_member_fm_ids.include?(bson_id)
    dup_th_members_exists = @th_member_ids.include?(bson_id)
    if dup_fms_exists
      if (dup_hbx_members_exists || dup_chms_exists)
      'other_dependencies'
      else
      'no_dependency'
      end
    end
  end

  def dup_chms_exists(bson_id)
    @chm_fm_ids.include?(bson_id)
  end

  def dup_hbx_members_exists(bson_id)
    @hbx_member_fm_ids.include?(bson_id)
  end

  def chhm_exists_for_other_fms(bson_id)
    family_member_ids = @duplicate_fms.map(&:id) - [bson_id]
    family_member_ids.any? { |family_member_id| @chm_fm_ids.include? family_member_id }
  end

  def matching_chhm(family, bson_id)
    ch = family.active_household.coverage_households.where("coverage_household_members.family_member_id" => bson_id).first
    ch.coverage_household_members.where(family_member_id: bson_id).first
  end

  def delete_matching_hbx_member(family, bson_id)
    deleted_ids = []
    shopping_enrollments = family.active_household.hbx_enrollments.where(:aasm_state.in => ["shopping"])
    if shopping_enrollments.present? && chhm_exists_for_other_fms(bson_id)
      enrollments = shopping_enrollments.where(:"hbx_enrollment_members.applicant_id" => bson_id)
      enrollments.each do |enr|
        matched_hem = enr.hbx_enrollment_members.where(:applicant_id => bson_id).first if enr.hbx_enrollment_members.present?
        matched_hem.delete
        deleted_ids << matched_hem.id
      end
      family.family_members.find(bson_id).delete if @family_member.present?
      @messages << "Removed duplicate hbx enrollment members with ids: #{deleted_ids} and family member with id: #{bson_id}"
    else
      @messages << 'Cannot destroy/delete the FamilyMember, reason: This FamilyMember does not have any Hbx Enrollment in shopping and does not have any other FamilyMember in the Family with CoverageHouseholdMember'
    end
  end

  def delete_duplicate_chhm(family, bson_id)
    # Check if there is any other Family Member record with a CoverageHouseholdMember before deleting this.
    if chhm_exists_for_other_fms(bson_id)
      chm = matching_chhm(family, bson_id)
      chm_id = chm.id
      chm.delete
      family.family_members.find(bson_id).delete
      @messages << "Removed duplicate coverage household member with id: #{chm_id} and family member with id: #{bson_id}"
    else
      @messages << 'Cannot destroy/delete the FamilyMember, reason: This FamilyMember does not have any other FamilyMember in the Family with CoverageHouseholdMember'
    end
  end

  def execute_removal_of_member(family, bson_id)
    set_instance_variables(family, bson_id)
    dependency_type = fetch_dependency_type(bson_id)

    if dependency_type == 'no_dependency'
      family.family_members.find(bson_id).delete
      @messages << "Removed duplicate family member id: #{bson_id}"
    elsif dependency_type == 'other_dependencies'
      delete_matching_hbx_member(family, bson_id) if dup_hbx_members_exists(bson_id)
      delete_duplicate_chhm(family, bson_id) if dup_chms_exists(bson_id)
    else
      @messages << 'Cannot destroy/delete the FamilyMember, reason: This family member has other dependencies other than the ones in the rake(Please enhance the rake)'
    end
  end

  def remove_duplicate_members(family_member_ids)
    @messages = []
    family_member_ids.each do |family_member_id|
      begin
        bson_id = BSON::ObjectId.from_string(family_member_id)
        family = Family.where("family_members._id" => bson_id).first
        if family.nil?
          @messages << "No family member found for id: #{bson_id}"
          next family_member_id
        end
        execute_removal_of_member(family, bson_id)
      rescue StandardError => e
        puts e.message unless Rails.env.test?
      end
    end
    [true, @messages]
  end
end
