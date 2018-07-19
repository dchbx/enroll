module BenefitSponsors
  class Enrollments::MemberEnrollment
    include ActiveModel::Model

    attr_accessor :member_id, :coverage_eligibility_on, :product_price,
                  :sponsor_contribution

    def initialize(opts = {})
      @member_id = nil
      @coverage_eligiblity_on = nil
      @product_price            = 0.00
      @sponsor_contribution     = 0.00
      super(opts)
    end

    def clone_for_coverage
      self.class.new({
       member_id: @member_id,
       coverage_eligibility_on: @coverage_eligibility_on
      })
    end

    def employee_cost
      product_price - sponsor_contribution
    end
  end
end
