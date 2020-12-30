# frozen_string_literal: true

# This script destroys the Primary to Primary relationships as current EA
# is not designed to store the same relationships
# rails runner script/destroy_primary_to_primary_relationships.rb -e production
require 'csv'
file_name = "#{Rails.root}/corrected_people_with_primary_to_primary_relationship.csv"
field_names = %w[person_hbx_id relationship_kind]

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names

  Person.where(:person_relationships.exists => true).each do |person|
    relationship_ids = person.person_relationships.where(relative_id: person.id).map(&:id)
    relationship_ids.each do |rel_id|
      kind = person.person_relationships.find(rel_id).kind
      person.person_relationships.find(rel_id).destroy!
      csv << [person.hbx_id, kind]
    end
  rescue StandardError => e
    puts "Errored processing person with hbx_id: #{person.hbx_id}, error: #{e.message}" unless Rails.env.test?
  end
end
