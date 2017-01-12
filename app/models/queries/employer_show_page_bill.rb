module Queries
  class EmployerShowPageBill < ::Queries::EmployerMonthlyEnrollments
    def execute
      enrollments_and_totals = get_decorators_for_enrollments
      OpenStruct.new(enrollments_and_totals)
    end
  end
end
