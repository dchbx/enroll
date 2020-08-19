class VerificationType
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person
  embedded_in :applicant, class_name: "::FinancialAssistance::Applicant"

  ALL_VERIFICATION_TYPES = ["DC Residency", "Social Security Number", "American Indian Status", "Citizenship", "Immigration status"]
  NON_CITIZEN_IMMIGRATION_TYPES = ["DC Residency", "Social Security Number", "American Indian Status"]
  ASSISTED_VERIFICATION_TYPES = %w[Income MEC].freeze

  VALIDATION_STATES = %w(na unverified pending review outstanding verified attested expired curam)
  OUTSTANDING_STATES = %w(outstanding)
  DUE_DATE_STATES = %w(review outstanding)

  field :type_name, type: String
  field :validation_status, type: String
  field :applied_roles, type: Array, default: ["consumer_role"] #[consumer_role, resident_role, ...]
  field :update_reason, type: String
  field :rejected, type: Boolean
  field :external_service, type: String
  field :due_date, type: Date
  field :due_date_type, type: String # admin, notice
  field :updated_by
  field :inactive, type: Boolean #use this field (assign true) only if type was present but for some reason if is not applicable anymore

  scope :active, -> { where(:inactive.ne => true ) }
  scope :by_name, ->(type_name) { where(:type_name => type_name) }
  scope :mec, ->{ where(:type_name => 'MEC') }
  scope :income, ->{ where(:type_name => 'Income') }

  # embeds_many :external_service_responses  -> needs datamigration
  embeds_many :type_history_elements


  embeds_many :vlp_documents, as: :documentable do
    def uploaded
      @target.select{|document| document.identifier }
    end
  end


  def type_unverified?
    !type_verified?
  end

  def type_verified?
    ["verified", "attested", "valid", "curam"].include? validation_status
  end

  def is_type_outstanding?
    validation_status == "outstanding"
  end

  def is_type_expired?
    validation_status == "expired"
  end

  def outstanding_no_docs?
    is_type_outstanding? && vlp_documents.empty?
  end

  def unverified_no_docs?
    type_unverified? && vlp_documents.empty?
  end

  def add_type_history_element(params)
    type_history_elements<<TypeHistoryElement.new(params)
  end

  def verif_due_date
    due_date || TimeKeeper.date_of_record + 95.days
  end

  def move_type_to_curam
    update_attributes(:validation_status => "curam")
  end

  def pass_type
    update_attributes(:validation_status => "verified")
  end

  def fail_type
    update_attributes(:validation_status => "outstanding")
  end

  def pending_type
    update_attributes(:validation_status => "pending")
  end

  def expire_type
    update_attributes(:validation_status => "expired", :update_reason => "Moved to Coverall")
  end

  def type_documents
    vlp_documents.select{|doc| doc.identifier.present?}
  end
end