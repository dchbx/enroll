# This rake task used to terminate employer active benefit application && active enrollments.
# RAILS_ENV=production bundle exec rake migrations:terminate_benefit_application['fein','end_on','termination_date']
# RAILS_ENV=production bundle exec rake migrations:terminate_benefit_application['522326356','02/28/2017','02/01/2017']
# RAILS_ENV=production bundle exec rake migrations:terminate_benefit_application['fein','end_on','termination_date', 'generate_termination_notice']
# RAILS_ENV=production bundle exec rake migrations:terminate_benefit_application['522326356','02/28/2017','02/01/2017',true/false]

namespace :migrations do
  desc "Terminating active benefit application and enrollments"
  task :terminate_benefit_application, [:fein, :end_on, :termination_date, :generate_termination_notice] => :environment do |task, args|
    fein = args[:fein]
    generate_termination_notice = (args[:generate_termination_notice].to_s == "true") ? true : false
    organizations = BenefitSponsors::Organizations::Organization.where(fein: fein)
    if organizations.size > 1
      puts "found more than 1 for #{legal_name}"
      raise 'more than 1 employer found with given fein'
    end

    puts "Processing #{organizations.first.legal_name}" unless Rails.env.test?
    termination_date = Date.strptime(args[:termination_date], "%m/%d/%Y")
    end_on = Date.strptime(args[:end_on], "%m/%d/%Y")
    organization = organizations.first

    # Expire previous year benefit applications
    organization.active_benefit_sponsorship.benefit_applications.published.where(:"effective_period.max".lte => TimeKeeper.date_of_record).each do |benefit_application|
      enrollment_service = initialize_service(benefit_application)
      enrollment_service.expire
    end
    # Terminate current active benefit applications
    organization.active_benefit_sponsorship.benefit_applications.published_benefit_applications_by_date(TimeKeeper.date_of_record).each do |benefit_application|
      enrollment_service = initialize_service(benefit_application)
      enrollment_service.terminate(end_on, termination_date)

      if benefit_application.terminated?
        if generate_termination_notice
          send_notice_to_employer(organization)
          send_notice_to_employees(organization, benefit_application)
        end

        # Cancel any renewal benefit applications that are present.
        if benefit_application.successor_applications.present?
          successor_application = benefit_application.successor_applications.first
          enrollment_service = initialize_service(successor_application)
          enrollment_service.cancel
        end
      end
      organization.active_benefit_sponsorship.terminate! if organization.active_benefit_sponsorship.may_terminate?
    end
  end

  # Deprecated - Not using for canceling benefit applications as of now
  # This rake task used to cancel renewing benefit application && renewing enrollments after terminating employer active benefit application.
  task :clean_terminated_employers, [:fein, :termination_date] => :environment do |fein, termination_date|

    organizations = Organization.where(fein: fein)

    if organizations.size > 1
      puts "found more than 1 for #{legal_name}"
    end

    puts "Processing #{organizations.first.legal_name}"
    termination_date = Date.strptime(termination_date, "%m/%d/%Y")

    organizations.each do |organization|
      successor_application = organization.active_benefit_sponsorship.benefit_applications
      if successor_application.present?
        enrollments = enrollments_for_plan_year(successor_application)
        enrollments.each do |enrollment|
          enrollment.cancel_coverage!
        end

        puts "found renewing plan year for #{organization.legal_name}---#{successor_application.effective_period.min}"
        successor_application.cancel_renewal! if successor_application.may_cancel_renewal?
      end
    end
  end

  def initialize_service(benefit_application)
    BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
  end

  def send_notice_to_employer(org)
    puts "group_advance_termination_confirmation:Notification generated for employer" unless Rails.env.test?
    begin
      ShopNoticesNotifierJob.perform_later(org.employer_profile.id.to_s, "group_advance_termination_confirmation")
    rescue Exception => e
      (Rails.logger.error { "Unable to deliver Notices to #{org.employer_profile.legal_name} that initial Employer’s plan year will not be written due to #{e}" }) unless Rails.env.test?
    end
  end


  def send_notice_to_employees(org, plan_year)
    org.employer_profile.census_employees.active.each do |ce|
      begin
        observer = Observers::Observer.new
        observer.trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "notify_employee_when_employer_requests_advance_termination")
      rescue Exception => e
        (Rails.logger.error { "Unable to deliver #{org.legal_name}'s termination notice to employee - #{ce.full_name} due to #{e}" }) unless Rails.env.test?
      end
    end
  end
end
