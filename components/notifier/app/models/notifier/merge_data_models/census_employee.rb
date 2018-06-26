module Notifier
  class MergeDataModels::CensusEmployee
    include Virtus.model
   
    attribute :latest_terminated_health_enrollment_plan_name, String
    attribute :latest_terminated_dental_enrollment_plan_name, String

    def self.stubbed_object
      notice = Notifier::MergeDataModels::CensusEmployee.new
      notice.latest_terminated_health_enrollment_plan_name = "Aetna Health Plan "
      notice.latest_terminated_dental_enrollment_plan_name = "Delta Dental Plan"
      notice
    end
  end
end