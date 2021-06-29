# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateSuperGroup < MongoidMigrationTask
  def migrate
    active_year = ENV["active_year"]
    hios_id = ENV["hios_id"]
    super_group_id = ENV["super_group_id"]

    message = ""
    message += "active_year," if active_year.blank?
    message += " hios_id," if hios_id.blank?
    message += " super_group_id" if super_group_id.blank?

    if message.present?
      puts "*" * 80 unless Rails.env.test?
      message += " cannot be empty."
      puts message
      puts "*" * 80 unless Rails.env.test?
      return
    end

    plan = Plan.where(active_year: active_year, hios_id: hios_id).first
    if plan.present?
      plan.carrier_special_plan_identifier = super_group_id
      plan.save
      puts "successfully updated plan with hios_id #{hios_id} in year #{active_year} with super_group_id #{plan.carrier_special_plan_identifier}" unless Rails.env.test?
    else
      puts "plan with hios_id #{hios_id} in year #{active_year} is not present" unless Rails.env.test?
    end

    product = ::BenefitMarkets::Products::Product.where(hios_id: hios_id).select{|a| a.active_year == active_year.to_i}.first
    if product.present?
      product.issuer_assigned_id = super_group_id
      product.save
      puts "successfully updated product with hios_id #{hios_id} in year #{active_year} with super_group_id #{product.issuer_assigned_id}" unless Rails.env.test?
    else
      puts "product with hios_id #{hios_id} in year #{active_year} is not present" unless Rails.env.test?
    end
  end
end
