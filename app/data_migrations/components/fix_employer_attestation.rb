require File.join(Rails.root, "lib/mongoid_migration_task")

class FixEmployerAttestation< MongoidMigrationTask
  def migrate

    organizations = BenefitSponsors::Organizations::Organization.where(:"profiles.employer_attestation.aasm_state" => 'unsubmitted')

    organizations.each do |organization|
      if ["conversion", "mid_plan_year_conversion"].include?(organization.active_benefit_sponsorship.source_kind.to_s)
        if organization.employer_profile.employer_attestation.present?
          employer_attestation = organization.employer_profile.employer_attestation
          employer_attestation.submit! if employer_attestation.may_submit?
          employer_attestation.approve! if employer_attestation.may_approve?
          employer_attestation.save!
          puts "updated employer attestation to #{employer_attestation.aasm_state} for organization #{organization.legal_name}" unless Rails.env.test?
        else
          employer_attestation = organization.employer_profile.create_employer_attestation
          employer_attestation.submit!  if employer_attestation.may_submit?
          employer_attestation.approve! if employer_attestation.may_approve?
          employer_attestation.save!
          puts "updated employer attestation to #{employer_attestation.aasm_state} for organization #{organization.legal_name}" unless Rails.env.test?
       end
      else
        organization.employer_profile.employer_attestation.employer_attestation_documents.each do |document|
          document.approve_attestation if document.accepted?
          document.deny_attestation if document.rejected?
          document.set_attestation_pending if document.info_needed?
          document.employer_attestation.submit! if document.submitted? && document.employer_attestation.may_submit?
          puts "updated employer attestation to #{document.employer_attestation.aasm_state} for organization #{organization.legal_name}" unless Rails.env.test?
        end
      end
    end
  end
end
