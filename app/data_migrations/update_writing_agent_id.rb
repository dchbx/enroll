require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateWritingAgentId < MongoidMigrationTask
  def migrate
    valid_writing_agent_id = ENV['valid_writing_agent_id']

    person = Person.where(hbx_id: ENV['hbx_id'])
    puts "Invalid hbx_id" unless person.present?
    accounts = person.first.primary_family.broker_agency_accounts if person.first.primary_family.present?
    active_accounts = accounts.detect { |account| account.is_active? } if accounts.any?
    active_accounts.update_attributes!(writing_agent_id: valid_writing_agent_id)
    puts "updated writing_agent_id for broker_agency_accounts" unless Rails.env.test?
  end
end
