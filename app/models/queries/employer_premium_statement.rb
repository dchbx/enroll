module Queries
  class EmployerPremiumStatement < ::Queries::EmployerMonthlyEnrollments
    def execute
      enrollments_and_totals = get_decorators_for_enrollments
      return nil if enrollments_and_totals.nil?
      sorted_enrollments = enrollments_and_totals[:hbx_enrollments].sort_by do |hbx_en|
        hbx_en.subscriber.person.last_name.downcase
      end
      OpenStruct.new(enrollments_and_totals.merge({:hbx_enrollments => sorted_enrollments}))
    end
  end
end
