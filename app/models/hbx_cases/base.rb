class HbxCases::Base
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Userstamp

  # Unique identifier for this case
  field :hbx_id, type: String

  # SHOP, Individual
  field :aca_market_kind, type: String

  # Which evidence group this case belongs to. Enumerated by each hbx_case class
  field :category_kind, type: String

  # External issue tracker system ID reference(s) in URI form
  field :associated_issue_ids, type: Array, default: []

  field :opened_at, type: Time
  field :closed_at, type: Time

  # Approval workflow
  # field :assigned_to,  type: BSON::ObjectId   # TODO: support multiple assignments
  # field :approved_by, type: BSON::ObjectId
  # belongs_to :user, inverse_of: :assigned_to
  # belongs_to :user, inverse_of: :approved_by

  embeds_one  :approval, as: :acceptable, class_name: "::Workflows::Approval"
  embeds_many :caseworker_notes,  as: :commentable
  embeds_many :customer_notes,    as: :commentable
  embeds_many :documents,         as: :documentable

  # Define relationships for linking cases
  has_many :associated_consumer_role_hbx_cases, class_name: "::HbxCases::ConsumerRole", inverse_of: :parent_consumer_role_hbx_case
  belongs_to :parent_consumer_role_hbx_case, class_name: "::HbxCases::ConsumerRole", inverse_of: :associated_consumer_role_hbx_cases

  has_many :associated_employee_role_hbx_cases, class_name: "::HbxCases::EmployeeRole", inverse_of: :parent_employee_role_hbx_case
  belongs_to :parent_employee_role_hbx_case, class_name: "::HbxCases::EmployeeRole", inverse_of: :associated_employee_role_hbx_cases

  has_many :associated_broker_role_hbx_cases, class_name: "::HbxCases::BrokerRole", inverse_of: :parent_broker_role_hbx_case
  belongs_to :parent_broker_role_hbx_case, class_name: "::HbxCases::BrokerRole", inverse_of: :associated_broker_role_hbx_cases

  has_many :associated_employer_profile_hbx_cases, class_name: "::HbxCases::EmployerProfile", inverse_of: :parent_employer_profile_hbx_case
  belongs_to :parent_employer_profile_hbx_case, class_name: "::HbxCases::EmployerProfile", inverse_of: :associated_employer_profile_hbx_cases

  # scope :is_assigned, ->{ any_in(aasm_state: ASSIGNED) }
  # scope :is_open,     ->{ any_in(aasm_state: OPEN) }
  # scope :is_closed,   ->{ any_in(aasm_state: CLOSED) }

  validates_presence_of :aca_market_kind, :category_kind

  before_save :set_case_open_timestamp

  # Enumerated list of events that triggered this case 
  # field :reason_kind, type: String
  # field :reason_text, type: String

private

  def set_case_open_timestamp
    self.opened_at = TimeKeeper.datetime_of_record if opened_at.blank?
  end


end
