require File.join(Rails.root, "lib/mongoid_migration_task")

class TriggerShopNotices < MongoidMigrationTask

  def migrate
    @ids_list = ENV['recipient_ids'].split(',').map(&:lstrip)
    @event = ENV['event']
    action = ENV['action'].to_s

    case action
    when "employer_notice"
      trigger_employer_notice
    when "employee_notice"
      trigger_employee_notice
    when "broker_notice"
      trigger_broker_notice
    when "general_agency_notice"
      trigger_general_agency_notice
    end
  end

  def trigger_employer_notice
    begin
      @ids_list.each do |fein|
        organization = Organization.where(fein: fein).first
        if organization.present?
          ShopNoticesNotifierJob.perform_later(organization.employer_profile.id.to_s, @event)
          puts "Notice of #{@event} delivered to #{organization.legal_name}" unless Rails.env.test?
        end
      end
    rescue Exception => e
      Rails.logger.error { "Unable to deliver #{@event} notice for #{organization.legal_name} due to #{e}" } unless Rails.env.test?
    end
  end

  def trigger_employee_notice
    # begin
    #   @ids_list.each do |hbx_id|
    #     census_employee = Person.where(hbx_id: hbx_id).first.active_employee_roles.first.census_employee # have to pick correct employee role if multiple
    #     if census_employee.present?
    #       ShopNoticesNotifierJob.perform_later(census_employee.id.to_s, @event)
    #       puts "Notice of #{@event} delivered to person with hbx_id: #{hbx_id}" unless Rails.env.test?
    #     end
    #   end
    # rescue Exception => e
    #   Rails.logger.error { "Unable to deliver #{@event} notice for person with hbx_id: #{hbx_id} due to #{e}" } unless Rails.env.test?
    # end
  end

  def trigger_broker_notice

  end

  def trigger_general_agency_notice

  end
end


