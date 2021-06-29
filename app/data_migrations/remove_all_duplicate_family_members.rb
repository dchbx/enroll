# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveAllDuplicateFamilyMembers < MongoidMigrationTask
  def initialize_instance_variables
    most_recent_active_enrollment_hbx_id = ENV['most_recent_active_enrollment_hbx_id'].to_s
    if most_recent_active_enrollment_hbx_id.blank?
      puts("Please supply the hbx_id of the most recent active HbxEnrollment for the family.") unless Rails.env.test?
      false
    else
      hbx_enrollment = HbxEnrollment.by_hbx_id(most_recent_active_enrollment_hbx_id).first
    end
    if hbx_enrollment.blank?
      puts("HbxEnrollment with this hbx_id does not exist.") unless Rails.env.test?
      false
    else
      @active_enrollment = hbx_enrollment
      @family = hbx_enrollment.family
      @person = hbx_enrollment.family.primary_person
      @authority_family_members_collection = authority_family_members_attached_to_most_recent_active_enrollment
      true
    end
  end

  def authority_family_members_attached_to_most_recent_active_enrollment
    active_enrollment_hbx_enrollment_members = @active_enrollment.hbx_enrollment_members
    authority_family_member_ids = []
    @family.family_members.each do |family_member|
      equivalent_hbx_member = active_enrollment_hbx_enrollment_members.detect { |hbx_member| hbx_member.family_member == family_member }
      if equivalent_hbx_member.present?
        # Applicant id is a family member id
        authority_family_member_ids << equivalent_hbx_member.applicant_id
      end
    end
    # Return as mongo collection so we can query
    @family.family_members.where(:_id.in => authority_family_member_ids)
  end

  def output_message
    unless Rails.env.test?
      @family.reload
      puts("Total family members: #{@family.family_members.count}")
      puts("Total coverage household members per coverage household member:")
      @family.active_household.coverage_households.each_with_index do |coverage_household, index|
        puts("Coverage household #{index}: #{coverage_household.coverage_household_members.count}")
      end
      puts("Total tax household members per coverage household member:")
      @family.active_household.tax_households.each_with_index do |tax_household, index|
        puts("Tax household #{index}: #{tax_household.tax_household_members.count}")
      end
      @family.hbx_enrollments.each_with_index do |enrollment, _index|
        puts("Enrollment with hbx_id #{enrollment.hbx_id} has #{enrollment.hbx_enrollment_members.count} HBX enrollment members.")
      end
    end
  end

  def destroy_coverage_household_and_tax_household_members
    @family.active_household.coverage_households.each do |coverage_household|
      puts("Destroying all coverage household members.") unless Rails.env.test?
      coverage_household.coverage_household_members.destroy_all
    end
    @family.active_household.tax_households.each do |tax_household|
      puts("Destroying all tax household members.") unless Rails.env.test?
      tax_household.tax_household_members.destroy_all
    end
  end

  def create_coverage_household_member(family_member)
    @family.active_household.coverage_households.each do |coverage_household|
      coverage_household.coverage_household_members.build(family_member_id: family_member.id).save!
    end
  end

  def create_tax_household_member(family_member)
    @family.active_household.tax_households.each do |tax_household|
      tax_household.tax_household_members.build(applicant_id: family_member.id).save!
    end
  end

  def destroy_unnecessary_shopping_enrollments
    shopping_enrollments = @family.hbx_enrollments.where(aasm_state: "shopping")
    return if shopping_enrollments.blank?
    shopping_enrollments.each(&:destroy)
  end

  # Make sure that any family members destroyed are not "authority" members attached to an enrollment
  def destroy_duplicate_family_members_unless_currently_enrolled
    # Delete duplicants by full name unless being used in current enrollment
    # First we need to update any cases where they might be being used for an enrollment
    authority_family_members_family_member_ids = @authority_family_members_collection.flat_map(&:id)
    @family.family_members.each do |fm|
      # Each time a family member is destroyed, the full names count
      # will change. Acting as a counter for how many family members
      @family.reload
      full_names = @family.family_members.map { |fm| fm.person.full_name }
      if full_names.count(fm.person.full_name) > 1 && authority_family_members_family_member_ids.exclude?(fm.id)
        puts("Full name appears more than once. Family member is duplicate. Deleting now.") unless Rails.env.test?
        fm.destroy
      elsif full_names.count(fm.person.full_name) == 1
        puts("Full name only appears once. Not deleting.") unless Rails.env.test?
      end
    end
  end

  def migrate
    if initialize_instance_variables
      destroy_unnecessary_shopping_enrollments
      destroy_duplicate_family_members_unless_currently_enrolled
      @family.reload
      family_members = @family.family_members
      # Coverage household members and tax household members are created just with family member ids, so all old ones
      # can safely be destroyed
      destroy_coverage_household_and_tax_household_members
      family_members.each do |family_member|
        create_coverage_household_member(family_member)
        create_tax_household_member(family_member)
      end
      output_message
    end
  rescue StandardError => e
    puts(e.message) unless Rails.env.test?
  end
end
