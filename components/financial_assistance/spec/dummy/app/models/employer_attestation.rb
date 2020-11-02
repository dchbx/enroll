# frozen_string_literal: true

class EmployerAttestation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :aasm_state, type: String, default: "unsubmitted"

  embedded_in :employer_profile
end
