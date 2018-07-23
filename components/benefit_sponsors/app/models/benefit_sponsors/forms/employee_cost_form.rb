module BenefitSponsors
  module Forms
    class EmployeeCostForm
      include Virtus.model

      attribute :name, String
      attribute :dependent_count, String
      attribute :highest_cost_estimate, String
      attribute :lowest_cost_estimate, String
      attribute :reference_estimate, String
    end
  end
end
