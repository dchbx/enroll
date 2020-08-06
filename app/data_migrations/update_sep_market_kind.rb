# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateSepMarketKind < MongoidMigrationTask
  def migrate
    file_name = "#{Rails.root}/report_for_sep_updated_family.csv"

    field_names = %w[family_id primary_hbx_id]

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      Family.no_timeout.exists(:special_enrollment_periods => true).each do |family|

        person = family.primary_applicant.person
        seps = family.special_enrollment_periods.select{ |sep| sep if sep.is_shop? && sep.market_kind == 'ivl'}
        seps.each do |sep|
          sep.update_attribute(:market_kind, "shop")
          csv << [family.id,
                  person.hbx_id]
          puts "sep updated for family with primary person #{family.primary_person.hbx_id}" unless Rails.env.test?
        end
      rescue StandardError => e
        puts "Cannot process family with id: #{family.id}, error: #{e.backtrace}"

      end
    end
  end
end
