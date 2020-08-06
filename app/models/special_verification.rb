# frozen_string_literal: true

class SpecialVerification
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :consumer_role

  TYPES = %w[admin notice].freeze

  field :due_date, type: Date
  field :verification_type
  field :updated_by
  field :type, type: String

  validates_presence_of :due_date, :verification_type
  validates :type,
            allow_blank: false,
            inclusion: {
              in: TYPES,
              message: "%{value} is not a valid type"
            }

  def admin_user
    User.find(self.updated_by) if self.updated_by.present?
  end
end
