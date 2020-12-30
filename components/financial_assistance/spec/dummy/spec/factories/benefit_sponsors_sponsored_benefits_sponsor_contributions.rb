# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_sponsored_benefits_sponsor_contribution, class: 'BenefitSponsors::SponsoredBenefits::SponsorContribution' do

    transient do
      product_package { nil }
    end

    after(:build) do |sponsor_contribution, evaluator|
      if evaluator.product_package
        product_package =  evaluator.product_package
        # TODO: This was originally just =
        if contribution_model == product_package.contribution_model
          contribution_model.contribution_units.each do |unit|
            contribution_unit = build(:benefit_sponsors_sponsored_benefits_contribution_level,
                                      sponsor_contribution: sponsor_contribution,
                                      display_name: unit.display_name,
                                      is_offered: true, order: unit.order,
                                      contribution_unit_id: unit.id,
                                      min_contribution_factor: unit.minimum_contribution_factor)

            case unit.display_name
            when 'Employee'
              contribution_unit.contribution_factor = 1.0
              contribution_unit.is_offered = true
            when 'Spouse'
              contribution_unit.contribution_factor = 0.80
              contribution_unit.is_offered = true
            when 'Domestic Partner'
              contribution_unit.contribution_factor = 0.55
              contribution_unit.is_offered = false
            when 'Child Under 26'
              contribution_unit.contribution_factor = 0.55
              contribution_unit.is_offered = false
            end
          end
        end
      end
    end
  end
end
