require File.join(Rails.root, "lib/mongoid_migration_task")

class FixOrganization< MongoidMigrationTask
  def migrate
    organization = get_organization
    action = ENV['action'].to_s
    case action
      when "update_fein"
        update_fein(organization) if organization.present?
      when "approve_attestation"
        approve_attestation_for_employer(organization) if organization.present?
      else
        puts"The Action defined is not performed in the rake task" unless Rails.env.test?
    end
  end

  def get_organization
  organization_count = BenefitSponsors::Organizations::Organization.where(fein: ENV['organization_fein']).count
    if organization_count!= 1
      raise "No Organization found (or) found more than 1 Organization record" unless Rails.env.test?
    else
      organization = BenefitSponsors::Organizations::Organization.where(fein: ENV['organization_fein']).first
      return organization
    end
  end


  def update_fein(organization)
    correct_fein = ENV['correct_fein']
      org_with_correct_fein = BenefitSponsors::Organizations::Organization.where(fein: correct_fein).first
      if org_with_correct_fein.present?
         puts "Organization was found by the given fein: #{correct_fein}" unless Rails.env.test?
      else
        organization.fein=(correct_fein)
        organization.save!
        puts "Changed fein to #{correct_fein}" unless Rails.env.test?
      end
  end
  def approve_attestation_for_employer(organization)
    employer= organization.employer_profile    
      attestation = employer.employer_attestation.blank?  ? employer.build_employer_attestation : employer.employer_attestation
      if attestation.present? && attestation.denied?      
        attestation.revert! if attestation.may_revert?
      end
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
end
