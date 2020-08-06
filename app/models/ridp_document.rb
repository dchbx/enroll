# frozen_string_literal: true

class RidpDocument < Document

  RIDP_DOCUMENTS_VERIF_STATUS = ['not submitted', 'downloaded', 'verified', 'rejected'].freeze

  # admin action list for verification process, dropdown for each ridp verification type
  ADMIN_VERIFICATION_ACTIONS = ["Verify", "Reject"].freeze

  # reasons admin can provide when verifying type
  VERIFICATION_REASONS = ["Document in EnrollApp", "Document in DIMS", "SAVE system", "E-Verified in Curam"].freeze

  # reasons admin can provide when returning for deficiency verification type
  RETURNING_FOR_DEF_REASONS = ["Illegible Document", "Member Data Change", "Document Expired", "Additional Document Required", "Other"].freeze

  RIDP_DOCUMENT_KINDS = ['Driver License'].freeze

  field :status, type: String, default: "not submitted"

  # ridp verification type this document can support: Driver's License
  field :ridp_verification_type, default: "Identity"

  field :comment, type: String

  field :uploaded_at, type: Date

  scope :uploaded, ->{ where(identifier: {:$exists => true}) }
end
