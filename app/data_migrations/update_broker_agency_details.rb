# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateBrokerAgencyProfile < MongoidMigrationTask

  def migrate
    action = ENV['action'].to_s
    @logger = Logger.new($stdout)
    legal_name = ENV['legal_name'].to_s

    service = BenefitSponsors::Services::UpdateBrokerAgencyService.new({legal_name: legal_name})

    case action

    when "corporate_npn"
      new_npn = ENV['corporate_npn'].to_s
      @logger.info "Trying to update corporate_npn"
      service.update_broker_agency_attributes({corporate_npn: new_npn})
      @logger.info "Updated corporate NPN is #{new_npn}"

    when "update_person"
      person_hbx_id = ENV['hbx_id'].to_s
      @logger.info "Trying to associate broker agency staff role to person with hbx_id #{person_hbx_id}"
      service.update_broker_profile_id({hbx_id: person_hbx_id})
      @logger.info "Updated person broker agency staff roles"

    when "update_start_date"
      org_hbx_ids = ENV['hbx_ids'].to_s.split
      start_date = DateTime.strptime(ENV['new_date'].to_s, "%m/%d/%Y")
      @logger.info "Trying to update start date on current person broker agency"
      service.update_broker_assignment_date({hbx_ids: org_hbx_ids, start_date: start_date})
      @logger.info "Updated the broker assigned start date of related person record"

    else
      @logger.warn "Unknown Action found"
    end
  end
end
