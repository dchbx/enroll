FactoryGirl.define do
  factory :paper_application do
    identifier "identifier"
    subject VlpDocument::VLP_DOCUMENT_KINDS[0] #I-327 (Reentry Permit) and validates on :alien_number
  end
end
