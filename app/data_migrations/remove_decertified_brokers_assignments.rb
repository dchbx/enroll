# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDecertifiedBrokersAssignments < MongoidMigrationTask
  def migrate
    people = Person.where("broker_role" => {"$exists" => true})

    people.each do |person|
      broker = person.broker_role
      next unless broker.aasm_state == "decertified" || broker.aasm_state == "broker_agency_pending"
      bap = broker.try(:broker_agency_profile)
      if bap.present? && bap.families.present?
        family = bap.families
        family.each(&:terminate_broker_agency)
      end
      orgs = Organization.by_broker_role(broker.id)
      employers = orgs.map(&:employer_profile)
      next unless employers.present?
      employers.each do |e|
        e.remove_decertified_broker_agency
        e.remove_general_agency_when_broker_decertified!(TimeKeeper.datetime_of_record)
      end
    end
  end
end