# This rake task used to cancel renewing benefit application and renewing enrollments.
# ex: RAILS_ENV=production bundle exec rake migrations:cancel_employer_renewal['521111111 522221111 5211333111']
namespace :migrations do
  desc "Cancel renewal for employer"
  task :cancel_benefit_application, [:fein] => [:environment] do |task, args|

    feins = args[:fein].split(' ').uniq

    feins.each do |fein|
      organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
      next puts "unable to find organization with fein: #{fein}" if organization.nil?
      renewing_benefit_application = organization.active_benefit_sponsorship.benefit_applications.is_renewing.first
      if renewing_benefit_application.present?
        puts "found renewing benefit application for #{organization.legal_name}---#{renewing_benefit_application.effective_period.min}" unless Rails.env.test?
        enrollment_service = initialize_service(renewing_benefit_application)
        enrollment_service.cancel
        organization.active_benefit_sponsorship.terminate! if organization.active_benefit_sponsorship.may_terminate?
      else
        puts "renewing benefit application not found for employer #{organization.legal_name}" unless Rails.env.test?
      end
    end
  end

# This rake task is used to cancel published benefit application & active enrollments.
# ex: RAILS_ENV=production bundle exec rake migrations:cancel_employer_incorrect_renewal['473089323 472289323 4730893333' ]

  desc "Cancel incorrect renewal for employer"
  task :cancel_employer_incorrect_renewal, [:fein] => [:environment] do |task, args|
    feins = args[:fein].split(' ').uniq
    feins.each do |fein|
      organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
      next puts "unable to find employer profile with fein: #{fein}" if organization.blank?
      benefit_application = organization.active_benefit_sponsorship.benefit_applications.published.first
      if benefit_application.present?
        puts "found  plan year for #{organization.legal_name}---#{plan_year.start_on}" unless Rails.env.test?
        enrollment_service = initialize_service(benefit_application)
        enrollment_service.cancel
        organization.active_benefit_sponsorship.terminate! if organization.active_benefit_sponsorship.may_terminate?
      else
        puts "renewing benefit application not found #{organization.legal_name}" unless Rails.env.test?
      end
    end
  end
end

def initialize_service(benefit_application)
  BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
end