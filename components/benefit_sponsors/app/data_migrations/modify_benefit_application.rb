# frozen_string_literal: true

require File.join(File.dirname(__FILE__), "..", "..", "lib/mongoid_migration_task")

class ModifyBenefitApplication < MongoidMigrationTask

  def migrate
    action = ENV['action'].to_s

    case action
    when "cancel"
      cancel_benefit_application(benefit_applications_for_cancel)
    when "terminate"
      terminate_benefit_application(benefit_applications_for_terminate)
    when "reinstate"
      reinstate_benefit_application(benefit_applications_for_reinstate)
    when "begin_open_enrollment"
      begin_open_enrollment(benefit_applications_for_aasm_state_update)
    when "update_effective_period_and_approve"
      update_effective_period_and_approve(benefit_applications_for_aasm_state_update)
    when "extend_open_enrollment"
      extend_open_enrollment
    when "force_submit_application"
      force_submit_application(benefit_application_for_force_submission)
    end
  end

  def extend_open_enrollment
    effective_date = Date.strptime(ENV['effective_date'], "%m/%d/%Y")
    oe_end_date = Date.strptime(ENV['oe_end_date'], "%m/%d/%Y") if ENV['oe_end_date'].present?

    benefit_sponsorship = get_benefit_sponsorship
    benefit_application = benefit_sponsorship.benefit_applications.where(:aasm_state.in => [:canceled, :enrollment_ineligible, :enrollment_extended, :enrollment_open, :enrollment_closed], :"effective_period.min" => effective_date).first

    raise "Unable to find benefit application!!" if benefit_application.blank?

    BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application).extend_open_enrollment(oe_end_date)
  end

  def begin_open_enrollment(benefit_applications)
    effective_date = Date.strptime(ENV['effective_date'], "%m/%d/%Y")
    benefit_application = benefit_applications.where(:aasm_state.in => [:approved, :enrollment_closed, :enrollment_eligible, :enrollment_ineligible], :"effective_period.min" => effective_date).first
    if benefit_application.present? && benefit_application.may_begin_open_enrollment?
      from_state = benefit_application.aasm_state
      benefit_application.update_attributes!(:aasm_state => :enrollment_open)
      benefit_application.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: from_state,
        to_state: "enrollment_open"
      )
      if from_state == :approved
        benefit_application.recalc_pricing_determinations
        benefit_application.renew_benefit_package_members
      end
      # We don't have the intermediate(initial) states on benefit_sponsorship any more
      # BS transitions from applicant to active
      # benefit_sponsorship = benefit_application.benefit_sponsorship
      # unless benefit_application.is_renewing?
      #   bs_from_state = benefit_sponsorship.aasm_state
      #   benefit_sponsorship.update_attributes!(aasm_state: "initial_enrollment_open")
      #   benefit_sponsorship.workflow_state_transitions << WorkflowStateTransition.new(
      #       from_state: bs_from_state,
      #       to_state: "initial_enrollment_open"
      #   )
      # end
      puts "aasm state has been changed to enrolling" unless Rails.env.test?
    else
      raise "FAILED: Unable to find application or application is in invalid state"
    end
  end

  def reinstate_benefit_application(benefit_applications); end

  def update_effective_period_and_approve(benefit_applications)
    effective_date = Date.strptime(ENV['effective_date'], "%m/%d/%Y")
    new_start_date = Date.strptime(ENV['new_start_date'], "%m/%d/%Y")
    new_end_date = Date.strptime(ENV['new_end_date'], "%m/%d/%Y")
    oe_start_on = new_start_date.prev_month
    oe_end_on = oe_start_on + 19.days
    raise 'new_end_date must be greater than new_start_date' if new_start_date >= new_end_date
    benefit_application = benefit_applications.where(:"effective_period.min" => effective_date, :aasm_state => :draft).first
    if benefit_application.present?
      benefit_sponsorship = benefit_application.benefit_sponsorship
      benefit_package = benefit_application.benefit_packages.detect(&:is_active)
      benefit_application.update_attributes!(effective_period: new_start_date..new_end_date, open_enrollment_period: oe_start_on..oe_end_on)
      new_effective_date = benefit_application.effective_period.min
      benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(new_effective_date)
      benefit_application.benefit_sponsor_catalog.delete
      benefit_sponsor_catalog.save!
      benefit_application.benefit_sponsor_catalog = benefit_sponsor_catalog
      update_contribution_unit_ids(benefit_application)
      benefit_application.save!
      benefit_sponsorship.census_employees.each do |ee|
        ee.benefit_group_assignments.where(benefit_package_id: benefit_package.id).each do |bga|
          bga.update_attributes!(start_on: new_start_date)
        end
      end
      benefit_application.approve_application!
      if benefit_application.is_renewing?
        bs_from_state = benefit_sponsorship.aasm_state
        if bs_from_state != "active"
          benefit_sponsorship.update_attributes!(aasm_state: "active")
          benefit_sponsorship.workflow_state_transitions << WorkflowStateTransition.new(
            from_state: bs_from_state,
            to_state: "active"
          )
        end
      end
    else
      raise "No benefit application found."
    end
  end

  def update_contribution_unit_ids(benefit_application)
    benefit_application.benefit_packages.each do |benefit_package|
      benefit_package.sponsored_benefits.each do |sponsored_benefit|
        sponsor_contribution = sponsored_benefit.sponsor_contribution
        sponsor_contribution.contribution_levels.each do |contribution_level|
          cu = sponsor_contribution.contribution_model.contribution_units.where(display_name: contribution_level.display_name).first
          raise "contribution_unit not found for #{benefit_application.benefit_sponsorship.legal_name} - contribution_level id - #{contribution_level.id}" unless cu

          next if cu.id == contribution_level.contribution_unit_id
          contribution_level.update_attributes!(contribution_unit_id: cu.id)
        end
      end
    end
  end

  def terminate_benefit_application(benefit_applications)
    termination_kind = ENV['termination_kind']
    termination_reason = ENV['termination_reason']
    off_cycle_renewal = ENV['off_cycle_renewal']
    termination_date = Date.strptime(ENV['termination_date'], "%m/%d/%Y")
    notify_trading_partner = ENV['notify_trading_partner'] == "true" || ENV['notify_trading_partner'] == true ? true : false
    end_on = Date.strptime(ENV['end_on'], "%m/%d/%Y")
    benefit_applications.each do |benefit_application|
      service = initialize_service(benefit_application)
      service.terminate(end_on, termination_date, termination_kind, termination_reason, notify_trading_partner)
    end
    revert_benefit_sponsorhip_to_applicant(benefit_applications.first.benefit_sponsorship) if benefit_applications.present? && off_cycle_renewal && (off_cycle_renewal.to_s.downcase == "true")
  end

  def revert_benefit_sponsorhip_to_applicant(benefit_sponsorship)
    from_state = benefit_sponsorship.aasm_state
    benefit_sponsorship.update_attributes!(aasm_state: :applicant)
    benefit_sponsorship.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: from_state,
      to_state: :applicant,
      reason: 'modify_benefit_application'
    )
  end

  def cancel_benefit_application(benefit_application)
    service = initialize_service(benefit_application)
    notify_trading_partner = ENV['notify_trading_partner'] == "true" || ENV['notify_trading_partner'] == true ? true : false
    service.cancel(notify_trading_partner)
  end

  def force_submit_application(benefit_application)
    service = initialize_service(benefit_application)
    service.force_submit_application
  end

  def benefit_applications_for_aasm_state_update
    benefit_sponsorship = get_benefit_sponsorship
    benefit_sponsorship.benefit_applications
  end

  def benefit_applications_for_reinstate; end

  def benefit_application_for_force_submission
    effective_date = Date.strptime(ENV['effective_date'], "%m/%d/%Y")
    benefit_sponsorship = get_benefit_sponsorship
    application = benefit_sponsorship.benefit_applications.where(:"effective_period.min" => effective_date)
    raise "Found #{application.count} benefit applications with that start date" if application.count != 1
    application.first
  end

  def benefit_applications_for_terminate
    benefit_sponsorship = get_benefit_sponsorship
    benefit_sponsorship.benefit_applications.published_benefit_applications_by_date(TimeKeeper.date_of_record)
  end

  def benefit_applications_for_cancel
    benefit_sponsorship = get_benefit_sponsorship
    benefit_application_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
    application = benefit_sponsorship.benefit_applications.where(:"effective_period.min" => benefit_application_start_on)
    raise "Found #{application.count} benefit applications with that start date" if application.count != 1
    application.first
  end

  def get_benefit_sponsorship
    fein = ENV['fein'].to_s
    organizations = BenefitSponsors::Organizations::Organization.where(fein: fein)
    if organizations.size != 1
      raise "Found no (OR) more than 1 organizations with the #{fein}" unless Rails.env.test?
    end
    organizations.first.active_benefit_sponsorship
  end

  def initialize_service(benefit_application)
    BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
  end
end
