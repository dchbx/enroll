# frozen_string_literal: true

# This job will terminate census employees in bulk
# We will call the terminate_employment on census_employee
# and pass the termination_date.
class BulkCensusEmployeesTerminationJob < ActiveJob::Base
  queue_as :default

  def perform(census_employee, employment_terminated_on)
    census_employee.terminate_employment(employment_terminated_on)
    puts "successfully terminated census employee #{census_employee.full_name}"
  end
end
