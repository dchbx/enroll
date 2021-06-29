# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class NotifyRenewalEmployeesDentalCarriersExitingShop < MongoidMigrationTask
  def migrate
    hbx_ids = ENV['hbx_id'].split(',').map(&:lstrip)
    hbx_ids.each do |hbx_id|
      person = Person.where(hbx_id: hbx_id).first
      enrollments = person.primary_family.active_household.hbx_enrollments.enrolled.by_coverage_kind("dental").shop_market.select{ |enr| enr.plan.present?} if person.present? && person.primary_family.present?
      next unless enrollments.present?
      enrollments.each do |hbx_enrollment|
        next unless ["Delta Dental", "MetLife"].include?(hbx_enrollment.plan.carrier_profile.organization.legal_name)
        ce = hbx_enrollment.census_employee
        ce.update_attributes!(employee_role_id: hbx_enrollment.employee_role.id.to_s) unless ce.employee_role.present?
        ShopNoticesNotifierJob.perform_later(ce.id.to_s, "notify_renewal_employees_dental_carriers_exiting_shop", { :hbx_enrollment => hbx_enrollment.hbx_id.to_s })
      end
    end
  rescue Exception => e
    Rails.logger.error {"Unable to deliver Dental Carriers Exiting SHOP Notice to Employee with hbx_id: #{hbx_id} due to #{e}"} unless Rails.env.test?
  end
end
