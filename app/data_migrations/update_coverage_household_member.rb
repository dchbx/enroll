# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCoverageHouseholdMember < MongoidMigrationTask
  def migrate
    # Rake task expects primary person's hbx_id ONLY
    person = Person.where(hbx_id: ENV['hbx_id'])
    raise "Invalid Hbx Id" if person.size != 1

    family = person.first.primary_family
    family.family_members.active.each do |member|
      family.active_household.add_household_coverage_member(member)
    end
    family.active_household.save
    puts "Added/Updated coverage household members for the family with primary #{ENV['hbx_id']}" unless Rails.env.test?
  end
end
