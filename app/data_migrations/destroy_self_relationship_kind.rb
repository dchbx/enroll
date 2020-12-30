# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
class DestroySelfRelationshipKind < MongoidMigrationTask
  def migrate
    # Expects primary person's hbx_id ONLY
    hbx_id = ENV['hbx_id'].to_s
    person = Person.where(hbx_id: hbx_id).first
    if person.primary_family.present?
      relationship_ids = person.person_relationships.where(relative_id: person.id).map(&:id)
      relationship_ids.each {|rel_id| person.person_relationships.find(rel_id).destroy! }
      puts "Changed person relationship type to self for hbx_id: #{hbx_id}" unless Rails.env.test?
    else
      puts "The person with hbx_id: #{hbx_id} is not a primary person of any family" unless Rails.env.test?
    end
  rescue StandardError => e
    puts "Bad Person Record with hbx_id: #{hbx_id}, error: #{e.message}" unless Rails.env.test?
  end
end
