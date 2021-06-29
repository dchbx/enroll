# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeBrokerDetails < MongoidMigrationTask
  def migrate
    market_kinds = ["individual", "shop", "both"]
    person = Person.where(hbx_id: ENV['hbx_id'])
    raise "Invalid Hbx Id" if person.size != 1
    market_kind = ENV['new_market_kind'].downcase
    if market_kinds.include?(market_kind)
      person.first.broker_role.update_attributes(market_kind: market_kind)
      puts "Updating market kind for Person with hbx id: #{ENV['hbx_id']} " unless Rails.env.test?
      person.first.broker_role.broker_agency_profile.update_attributes(market_kind: market_kind)
      puts "update the market kind under broker agency profile to: #{market_kind}" unless Rails.env.test?
    else
      puts "Bad Market Kind" unless Rails.env.test?
    end
  rescue StandardError
    puts "Bad Person Record" unless Rails.env.test?
  end
end