require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateConversionFlag < MongoidMigrationTask
  def migrate
    begin
      feins = ENV['fein'].split(',').map(&:lstrip)
      feins.each do |fein|
        organization = Organization.where(fein: fein)
        if organization.size != 1
          puts "Issues with organization of fein #{fein}" unless Rails.env.test?
          next
        end
        emp = organization.first.employer_profile
        
        if ENV['profile_source'] == "self_serve"
          attestation_doc(emp)
        else
          emp.update_attributes!(profile_source: ENV['profile_source'])
          puts "Conversion flag updated #{ENV['profile_source']} for #{fein}" unless Rails.env.test?
          attestation_doc(emp)
        end
      end
    rescue Exception => e
      puts e.message
    end
  end

  def attestation_doc(employer)
    attestation = employer.employer_attestation.blank?  ? employer.build_employer_attestation : employer.employer_attestation
    if attestation.present? && attestation.denied?
      attestation.revert! if attestation.may_revert?
      document = attestation.employer_attestation_documents.where(:aasm_state.ne =>"accepted").first
      unless document.present?
        puts "Employer attestation document not found" unless Rails.env.test?
      else
        document.revert! if document.present? && document.may_revert?
        document.submit! if document.may_submit?
        document.accept! if document.may_accept?
      end
    end
    attestation.submit! if attestation.may_submit?
    attestation.approve! if attestation.may_approve?
    attestation.save
    puts "Employer Attestation approved" unless Rails.env.test?
  end
end
