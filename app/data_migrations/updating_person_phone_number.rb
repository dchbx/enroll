# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdatingPersonPhoneNumber < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id'])

    raise 'Issues with hbx_id' if person.size != 1

    work_phone = person.first.phones.where(kind: 'work').first
    work_phone.update_attributes!(area_code: ENV['area_code'],number: ENV['number'],extension: ENV['ext'],full_phone_number: ENV['full_number'])
  end
end