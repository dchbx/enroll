# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
require File.join(Rails.root, "lib", "remove_family_member")

class RemoveDependent < MongoidMigrationTask
  include RemoveFamilyMember

  def migrate
    family_member_ids = ENV['family_member_ids'].to_s.split(',').uniq
    status, messages = remove_duplicate_members(family_member_ids)
    messages.each do |message|
      puts message unless Rails.env.test?
    end
  end
end
