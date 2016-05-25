FactoryGirl.define do
  factory :vlp_document do
    alien_number "123456789"
    receipt_number "abc4567890123"
    expiration_date Date.today
    issuing_country "USA"
    identifier "identifier"
    country_of_citizenship "Ukraine"
    passport_number "123456"
    subject VlpDocument::VLP_DOCUMENT_KINDS[0] #I-327 (Reentry Permit) and validates on :alien_number
  end
end
