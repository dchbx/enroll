class HbxEnrollmentSponsoredCostCalculator
  def initialize(original_enrollment)
    @member_group = original_enrollment.as_shop_member_group
    @sponsored_benefit = original_enrollment.sponsored_benefit
    @pricing_model = @sponsored_benefit.pricing_model
    @contribution_model = @sponsored_benefit.contribution_model
    @pricing_calculator = @sponsored_benefit.pricing_calculator
    @contribution_calculator = @sponsored_benefit.contribution_calculator
    @sponsor_contribution = @sponsored_benefit.sponsor_contribution
  end

  def groups_for_products(products)
    @groups_for_products ||= calculate_groups_for_products(products)
  end

  protected

	def calculate_groups_for_products(products)
		products.map do |product|
			member_group_with_product = @member_group.clone_for_coverage(product)
			member_group_with_pricing = @pricing_calculator.calculate_price_for(@pricing_model, member_group_with_product, @sponsor_contribution)
			@contribution_calculator.calculate_contribution_for(@contribution_model, member_group_with_pricing, @sponsor_contribution)
		end
	end
end
