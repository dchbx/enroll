class SpecialVerification
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :consumer_role

  field :due_date
  field :verification_type
  field :updated_by

  validates_presence_of :due_date, :verification_type, :updated_by

  def admin_user
    User.find(self.updated_by)
  end
end
