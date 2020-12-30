# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_benefit_sponsorships_benefit_sponsorship_account, class: 'BenefitSponsors::BenefitSponsorships::BenefitSponsorshipAccount' do
    next_premium_due_on   { TimeKeeper.date_of_record.end_of_month + 1.day }
    next_premium_amount   { 5489.97 }
    past_due              { 344.90 }
    previous_balance      { 90.08 }
    new_charges           { 223.29 }
    adjustments           { 23.09 }
    payments              { 908.8 }
    total_due             { 89.75 }
    current_statement_date{ TimeKeeper.date_of_record.next_month.beginning_of_month }

    trait :with_financial_transactions do
      after :build do |benefit_sponsorship_account, _evaluator|
        FactoryBot.create(:benefit_sponsors_benefit_sponsorships_financial_transaction, benefit_sponsorship_account: benefit_sponsorship_account)
      end
    end

    trait :with_current_statement_activities do
      after :build do |benefit_sponsorship_account, _evaluator|
        FactoryBot.create(:benefit_sponsors_benefit_sponsorships_current_statement_activity, benefit_sponsorship_account: benefit_sponsorship_account)
      end
    end
  end
end