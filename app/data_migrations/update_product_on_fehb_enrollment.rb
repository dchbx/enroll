# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateProductOnFehbEnrollment < MongoidMigrationTask

  def migrate
    feins = (ENV['feins']).to_s.split(',').uniq
    logger = Logger.new("#{Rails.root}/log/update_product_on_fehb_enrollment_log_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log") unless Rails.env.test?

    feins.each do |fein|

      organization = ::BenefitSponsors::Organizations::Organization.where(fein: fein).first
      logger.info("Processing #{organization.legal_name} -- #{organization.fein}") unless Rails.env.test?

      employer_profile = organization.employer_profile
      employer_profile.census_employees.no_timeout.each do |ce|
        next unless ce.employee_role.present?
        person = ce.employee_role.person
        enrollments = enrollments_effective_on(person, Date.new(2020,1,1))
        enrollments.each do |enrollment|
          next unless enrollment.fehb_profile.present?

          current_product = enrollment.product
          next if !current_product || current_product&.benefit_market_kind.to_s == 'fehb'

          fehb_product = BenefitMarkets::Products::Product.where(
            :hios_base_id => /#{current_product.hios_base_id}/,
            :"application_period.min".gte => Date.new(current_product.active_year, 1, 1), :"application_period.max".lte => Date.new(current_product.active_year, 1, 1).end_of_year,
            :kind => current_product.kind,
            :benefit_market_kind => :fehb
          ).first
          if fehb_product.present?
            enrollment.update_attributes(:product_id => fehb_product.id)
            logger.info("Updated Enrollment #{enrollment.hbx_id} for the person with hbx id #{person.hbx_id} under employer #{organization.legal_name}") unless Rails.env.test?
          end
        end
      end
    end
  rescue Exception => e
    puts e.message
  end

  def enrollments_effective_on(person, effective_date)
    person.primary_family.active_household.hbx_enrollments.shop_market.where(:effective_on.gte => effective_date, :aasm_state.nin => ["shopping", "coverage_canceled"])
  end
end
