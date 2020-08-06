# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_documents_employer_attestation, class: 'BenefitSponsors::Documents::EmployerAttestation' do
    aasm_state { "unsubmitted" }

    trait :with_attestation_document do
      after :create do |employer_attestation, _evaluator|
        employer_attestation_documents { [FactoryBot.create(:benefit_sponsors_documents_employer_attestation_document, employer_attestation: employer_attestation)] } if employer_attestation.submitted?
      end
    end
  end
end
