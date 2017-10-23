FactoryGirl.define do
  factory :ridp_document do
    identifier "identifier"
    ridp_verification_type 'Identity'
    subject RidpDocument::RIDP_DOCUMENT_KINDS[0]
  end
end