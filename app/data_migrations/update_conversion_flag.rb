# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateConversionFlag < MongoidMigrationTask
  def migrate
    feins = ENV['fein'].split(',').map(&:lstrip)
    feins.each do |fein|
      benefit_sponsorship = ::BenefitSponsors::Organizations::Organization.where(:fein => fein).first.active_benefit_sponsorship
      if benefit_sponsorship
        emp = benefit_sponsorship.profile
        if ENV['source_kind'] == "self_serve"
          attestation_doc(emp)
        else
          benefit_sponsorship.update_attributes!(source_kind: ENV['source_kind'].to_sym)
          puts "Conversion flag updated #{ENV['source_kind']} for #{fein}" unless Rails.env.test?
          attestation_doc(emp)
        end
      else
        puts "Issues with benefit_sponsorship of fein #{fein}" unless Rails.env.test?
        next
      end
    end
  rescue StandardError => e
    puts e.message
  end

  def attestation_doc(employer)
    attestation = employer.employer_attestation.presence || employer.build_employer_attestation
    if attestation.present? && attestation.denied?
      attestation.revert! if attestation.may_revert?
      document = attestation.employer_attestation_documents.where(:aasm_state.ne => "accepted").first
      if document.present?
        document.revert! if document.present? && document.may_revert?
        document.submit! if document.may_submit?
        document.accept! if document.may_accept?
      else
        puts "Employer attestation document not found" unless Rails.env.test?
      end
    end
    attestation.submit! if attestation.may_submit?
    attestation.approve! if attestation.may_approve?
    attestation.save
    puts "Employer Attestation approved" unless Rails.env.test?
  end
end