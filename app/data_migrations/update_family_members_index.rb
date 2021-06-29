# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateFamilyMembersIndex < MongoidMigrationTask
  def migrate
    action_task = ENV['action_task']
    case action_task
    when "update_family_member_index"
      update_family_member_index
    when "update_family_id"
      update_family_member_id
    when nil
      puts "Please enter action to run the rake task" unless Rails.env.test?
    else
      puts "The Action defined is not performed in the rake task" unless Rails.env.test?
    end
  end

  def primary_person
    Person.where(hbx_id: ENV['primary_hbx']).first if Person.present?
  end

  def update_family_member_index
    dependent_person = Person.where(hbx_id: ENV['dependent_hbx']).first
    if primary_person.present? && dependent_person.present?
      family_members = primary_person.families.first.family_members
      family_members.where(id: ENV['dependent_family_id']).first.unset(:person_id)
      family_members.where(id: ENV['primary_family_id']).first.update_attributes(person_id: primary_person.id, is_primary_applicant: true)
      family_members.where(id: ENV['dependent_family_id']).first.update_attributes(person_id: dependent_person.id, is_primary_applicant: false)
      puts "family_member_index_updated" unless Rails.env.test?
    else
      raise "some error person with hbx_id:#{ENV['primary_hbx']} and hbx_id:#{ENV['dependent_hbx']} not found"
    end
  end

  def update_family_member_id
    coverage_household = primary_person.primary_family.active_household.coverage_households.where(:is_immediate_family => true).first
    old_family_id = ENV['old_family_id'].to_s
    correct_family_id = ENV['correct_family_id'].to_s
    if primary_person.present?
      coverage_household_member = coverage_household.coverage_household_members.where(family_member_id: old_family_id).first if old_family_id.present?
      coverage_household_member.update_attributes!(family_member_id: correct_family_id)
      puts "family_member_id_updated" unless Rails.env.test?
    end
  rescue StandardError => e
    puts "error: #{e.backtrace}" unless Rails.env.test?
  end
end
