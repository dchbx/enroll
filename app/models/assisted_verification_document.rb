class AssistedVerificationDocument < Document

  #list of assisted verification kinds
  VERIFICATION_TYPES = FinancialAssistance::AssistedVerification::VERIFICATION_TYPES

  VLP_DOCUMENTS_VERIF_STATUS = ['not submitted', 'downloaded', 'verified', 'rejected']


  # admin action list for verification process, dropdown for each verification type
  ADMIN_VERIFICATION_ACTIONS = ["Verify", "Return for Deficiency", "Reject Document", "Clear Status", "View History", "Call HUB"]

  # reasons admin can provide when verifying type
  VERIFICATION_REASONS = ["Document in EnrollApp", "Document in DIMS", "SAVE system", "E-Verified in Curam"]

  # The set of ID fields represent the document tied to a particular verification for an applicant in an application.
  field :application_id, type: BSON::ObjectId
  field :applicant_id, type: BSON::ObjectId
  field :assisted_verification_id, type: BSON::ObjectId

  field :status, type: String, default: "not submitted"
  field :kind, type: String
  field :comment, type: String

  validates_presence_of :application_id, :applicant_id, :assisted_verification_id

  validates :kind,
      inclusion: { in: VERIFICATION_TYPES, message: "%{value} is not a defined verification type" }

  scope :uploaded, ->{ where(identifier: {:$exists => true}) }

  def is_income?
    kind == 'Income'
  end

  def is_mec?
    kind == 'MEC'
  end

  def status
    return nil unless assisted_verification
    assisted_verification.status
  end

  def kind
    return nil unless assisted_verification
    assisted_verification.verification_type
  end

  def assisted_verification
    FinancialAssistance::Application.where(id: application_id).first.applicants.where(id: applicant_id).first.assisted_verifications.where(id: assisted_verification_id).first
  end

  def family
    FinancialAssistance::Application.where(id: application_id).first.family
  end
end
