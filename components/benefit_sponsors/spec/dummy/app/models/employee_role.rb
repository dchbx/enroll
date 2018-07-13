class EmployeeRole
  include Mongoid::Document

  embedded_in :person
end
