# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateFehbOeDatesAndContributionCap < MongoidMigrationTask

  def migrate
    action = ENV['action'].to_s
    feins = ENV['feins'].split.uniq
    feins.each do |fein|
      organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
      effective_on = DateTime.strptime(ENV['effective_on'], "%m/%d/%Y")
      benefit_application = organization.employer_profile.benefit_applications.where(:"effective_period.min" => effective_on).first

      case action
      when 'update_open_enrollment_dates'
        update_open_enrollment_dates(benefit_application)
      when 'update_contribution_cap'
        update_contribution_cap(benefit_application)
      when 'begin_open_enrollment'
        begin_open_enrollment(benefit_application)
      end
    end
  end

  def update_open_enrollment_dates(benefit_application)
    oe_start_on = DateTime.strptime(ENV['oe_start_on'].to_s, "%m/%d/%Y")
    oe_end_on = DateTime.strptime(ENV['oe_end_on'].to_s, "%m/%d/%Y")

    benefit_application.update_attributes("open_enrollment_period" => oe_start_on..oe_end_on)
  rescue StandardError => e
    puts e.message
  end

  def update_contribution_cap(benefit_application)
    contribution_levels = benefit_application.benefit_packages.first.sponsored_benefits.first.sponsor_contribution.contribution_levels
    contribution_levels.where(:display_name => 'Employee Only').first.update_attributes(contribution_cap: ENV['employee_only_cap']) if ENV['employee_only_cap']
    contribution_levels.where(:display_name => 'Employee + 1').first.update_attributes(contribution_cap: ENV['employee_plus_one_cap']) if ENV['employee_plus_one_cap']
    contribution_levels.where(:display_name => 'Family').first.update_attributes(contribution_cap: ENV['family_cap']) if ENV['family_cap']
  rescue StandardError => e
    puts e.message
  end

  def begin_open_enrollment(benefit_application)
    service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
    service.submit_application
  rescue StandardError => e
    puts e.message
  end
end