# frozen_string_literal: true

class Transaction
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  field :application_type, type: String
  field :aasm_state, type: String

  aasm do
    state :enrollment_closed, initial: true
    state :open_enrollment_period
    state :special_enrollment_period
    state :open_and_special_enrollment_period

    event :open_enrollment do
      transitions from: :open_enrollment_period, to: :open_enrollment_period
      transitions from: :special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :enrollment_closed, to: :open_enrollment_period
    end

    event :close_open_enrollment do
      transitions from: :open_enrollment_period, to: :enrollment_closed
      transitions from: :special_enrollment_period, to: :special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :special_enrollment_period
      transitions from: :enrollment_closed, to: :enrollment_closed
    end

    event :open_special_enrollment do
      transitions from: :open_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :special_enrollment_period, to: :special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :enrollment_closed, to: :special_enrollment_period
    end

    event :close_special_enrollment do
      transitions from: :open_enrollment_period, to: :open_enrollment_period
      transitions from: :special_enrollment_period, to: :enrollment_closed
      transitions from: :open_and_special_enrollment_period, to: :open_enrollment_period
      transitions from: :enrollment_closed, to: :enrollment_closed
    end
  end
end
