# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePersonFamilyMemberLinkage < MongoidMigrationTask

  def migrate
    person = Person.where(hbx_id: ENV['hbx_id']).first
    if person.blank?
      puts "No person found for #{ENV['hbx_id']}" unless Rails.env.test?
    else
      family = Family.where("family_members._id" => BSON::ObjectId(ENV['family_member_id'])).first
      family_member = family.family_members.detect{|fm| fm.id == BSON::ObjectId(ENV['family_member_id'])}
      family_member.update_attributes!(:person_id => person._id)
    end
  end

end