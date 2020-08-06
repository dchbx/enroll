# frozen_string_literal: true

FactoryBot.define do
  factory :plan_design_benefit_sponsorship, class: 'SponsoredBenefits::BenefitSponsorships::BenefitSponsorship' do
    benefit_market { 'aca_shop_cca' }
    initial_enrollment_period { TimeKeeper.date_of_record.beginning_of_month..(TimeKeeper.date_of_record.beginning_of_month + 15.days) }
  end
end
