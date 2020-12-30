# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ExtendBrokerApplication < MongoidMigrationTask

  def migrate
    npn = ENV['broker_npn'].to_s
    broker_role = BrokerRole.by_npn(npn).first

    unless broker_role
      puts "No broker role found with the give npn - #{npn}" unless Rails.env.test?
      return
    end

    broker_agency_profile_id = broker_role.broker_agency_profile.id
    person_id = broker_role.person.id

    service = broker_reapplication_service(broker_agency_profile_id, person_id)
    result, _broker = service.re_apply

    if result
      puts "Successfully extended the broker application for broker with npn #{npn}." unless Rails.env.test?
    else
      puts 'Unable to extend broker application.' unless Rails.env.test?
    end
  end

  def broker_reapplication_service(broker_agency_profile_id, person_id)
    ::BenefitSponsors::Services::StaffRoleReapplicationService.new({profile_id: broker_agency_profile_id, person_id: person_id})
  end
end