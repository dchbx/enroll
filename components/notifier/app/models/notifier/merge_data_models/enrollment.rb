module Notifier
  class MergeDataModels::Enrollment
    include Virtus.model

    attribute :coverage_start_on, String
    attribute :coverage_end_on, String
    attribute :plan_name, String
    attribute :enrolled_count, String
    # attribute :metal_level, String
    attribute :coverage_kind, String
    # attribute :plan_carrier, String
    attribute :employee_responsible_amount, String
    attribute :employer_responsible_amount, String
    attribute :employee_first_name, String
    attribute :employee_last_name, String

    def self.stubbed_object
      Notifier::MergeDataModels::Enrollment.new({
        coverage_start_on: TimeKeeper.date_of_record.beginning_of_year,
        coverage_end_on: TimeKeeper.date_of_record.end_of_month,
        plan_name: 'KP SILVER',
        enrolled_count: '2',
        coverage_kind: 'dental',
        employer_responsible_amount: '$250.0',
        employee_responsible_amount: '$90.0',
        employee_first_name: 'David',
        employee_last_name: 'Finch',
        })
    end
  end
end