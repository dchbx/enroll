module SponsoredBenefits
  module RatingModels
    class ReferencePlanPercentCreditStructure < CreditStructure
      include Mongoid::Document
      include Mongoid::Timestamps

      field :reference_plan_hbx_id,         type: String
      field :contribution_percent_minimum,  type: Integer

      validate :contribution_percent_minimum,
                numericality: {only_integer: true, inclusion: 0..100},
                allow_nil: false

      def reference_plan=(new_reference_plan)
        write_attribute(:reference_plan_hbx_id, new_reference_plan.hbx_id)
        @reference_plan = new_reference_plan
      end

      def reference_plan
        return unless reference_plan_hbx_id.present?
        return @reference_plan if defined? @reference_plan

        @reference_plan = SponsoredBenefits::BenefitCatalogs::Product.find_by_hbx_id(reference_plan_hbx_id)
      end


    end
  end
end
