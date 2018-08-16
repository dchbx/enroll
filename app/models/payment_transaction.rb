class PaymentTransaction
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :family

  field :payment_transaction_id, type: String
  field :carrier_id, type: BSON::ObjectId
  field :enrollment_effective_date, type: Date
  field :enrollment_id, type: BSON::ObjectId
  field :status, type: String
  field :body, type: String
  field :submitted_at, type: DateTime

  before_save :generate_payment_transaction_id, :set_submitted_at

  def generate_payment_transaction_id
    write_attribute(:payment_transaction_id, HbxIdGenerator.generate_payment_transaction_id) if payment_transaction_id.blank?
  end

  def set_submitted_at
    self.submitted_at ||= TimeKeeper.datetime_of_record
  end

  def update_enrollment_details(enrollment)
    self.enrollment_id = enrollment.id
    self.carrier_id =  enrollment.plan.carrier_profile_id
    self.enrollment_effective_date = enrollment.effective_on
    self.save!
  end

  def self.build_payment_instance(enrollment)
    payment = enrollment.family.payment_transactions.build
    payment.update_enrollment_details(enrollment)
    payment.family.save!
    payment
  end
end
