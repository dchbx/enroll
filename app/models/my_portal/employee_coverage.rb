class EmployeeCoverage
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_staff_role

  field :encrypted_ssn, type: String
  field :dob, type: Date
  field :hired_on, type: Date
  field :state, type: String, default: 'pending'

  default_scope ->{ where(is_active: true) }

end
