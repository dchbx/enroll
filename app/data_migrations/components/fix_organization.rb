# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class FixOrganization < MongoidMigrationTask
  def migrate
    organization = get_organization
    action = ENV['action'].to_s
    case action
    when "update_fein"
      update_fein(organization) if organization.present?
    when "swap_fein"
      swap_fein(organization) if organization.present?
    when "approve_attestation"
      approve_attestation_for_employer(organization) if organization.present?
    when "update_employer_broker_agency_account"
      update_employer_broker_agency_account(organization) if organization.present?
    else
      puts "The Action defined is not performed in the rake task" unless Rails.env.test?
    end
  end

  def get_organization
    organization_count = BenefitSponsors::Organizations::Organization.where(fein: ENV['organization_fein']).count
    if organization_count == 1
      BenefitSponsors::Organizations::Organization.where(fein: ENV['organization_fein']).first
    else
      raise "No Organization found (or) found more than 1 Organization record" unless Rails.env.test?

    end
  end

  def update_fein(organization)
    correct_fein = ENV['correct_fein']
    org_with_correct_fein = BenefitSponsors::Organizations::Organization.where(fein: correct_fein).first
    if org_with_correct_fein.present?
      puts "Organization was found by the given fein: #{correct_fein}" unless Rails.env.test?
    else
      organization.fein = (correct_fein)
      organization.save!
      puts "Changed fein to #{correct_fein}" unless Rails.env.test?
    end
  end

  def swap_fein(organization)
    correct_fein = ENV['correct_fein']
    organization_with_wrong_fein = organization.fein
    org_with_correct_fein = BenefitSponsors::Organizations::Organization.where(fein: correct_fein).first
    if org_with_correct_fein.present?
      org_with_correct_fein.unset(:fein)
      organization.set(fein: correct_fein)
      org_with_correct_fein.set(fein: organization_with_wrong_fein)
      puts "Feins swapped between the Organizations of #{org_with_correct_fein.hbx_id} and #{organization.hbx_id}" unless Rails.env.test?
    else
      puts "No Organization found to swap the fein with" unless Rails.env.test?
    end
  end

  def approve_attestation_for_employer(organization)
    employer = organization.employer_profile
    attestation = employer.employer_attestation.blank? ? employer.build_employer_attestation : employer.employer_attestation
    attestation.revert! if attestation.present? && attestation.denied? && attestation.may_revert?
    documents = attestation.employer_attestation_documents
    if documents.present?
      documents.each do |document|
        document.revert! if document.present? && document.may_revert?
        document.employer_attestation.submit! if document.submitted? && document.employer_attestation.may_submit?
        document.accept if document.submitted?
        document.approve_attestation if document.accepted?
      end
    else
      puts "Employer attestation document not found" unless Rails.env.test?
    end
    attestation.submit! if attestation.may_submit?
    attestation.approve! if attestation.may_approve?
    attestation.save
    puts "Employer Attestation approved" unless Rails.env.test?
  end

  def update_employer_broker_agency_account(organization)
    correct_npn = ENV['npn']
    writing_agent = BrokerRole.by_npn(correct_npn).first
    broker_agency_profile = writing_agent.broker_agency_profile if writing_agent.present?

    if broker_agency_profile.present?
      broker_agency_account = organization.active_benefit_sponsorship.active_broker_agency_account
      if broker_agency_account.present?
        hired_on = broker_agency_account.start_on
        employer_profile = organization.employer_profile
        employer_profile.broker_role_id = writing_agent.id
        employer_profile.hire_broker_agency(broker_agency_profile, hired_on)
        employer_profile.save!
        puts "broker_agency_profile and writing_agent updated for broker_agency_account" unless Rails.env.test?
      else
        puts "No broker_agency_account found for organization fein:#{fein}" unless Rails.env.test?
      end
    else
      puts "broker_agency_profile not found for broker" unless Rails.env.test?
    end
  end
end
