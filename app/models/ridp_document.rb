class RidpDocument < Document


  RIDP_DOCUMENTS_VERIF_STATUS = ['not submitted', 'downloaded', 'verified', 'rejected']


  # admin action list for verification process, dropdown for each verification type
  ADMIN_VERIFICATION_ACTIONS = ["Verify", "Reject"]

  # reasons admin can provide when verifying type
  VERIFICATION_REASONS = ["Document in EnrollApp", "Document in DIMS", "SAVE system", "E-Verified in Curam"]

  # reasons admin can provide when returning for deficiency verification type
  RETURNING_FOR_DEF_REASONS = ["Illegible Document", "Member Data Change", "Document Expired", "Additional Document Required", "Other"]

  RIDP_DOCUMENT_KINDS = ['Driver License']

  field :status, type: String, default: "not submitted"

  # verification type this document can support: Social Security Number, Driver's License
  field :ridp_verification_type, default: "Identity"

  field :comment, type: String

  field :uploaded_at, type: Date

  scope :uploaded, ->{ where(identifier: {:$exists => true}) }


end

