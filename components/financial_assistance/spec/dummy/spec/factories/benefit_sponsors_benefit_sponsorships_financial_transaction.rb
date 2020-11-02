# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_benefit_sponsorships_financial_transaction, class: 'BenefitSponsors::BenefitSponsorships::FinancialTransaction' do
    paid_on               { TimeKeeper.date_of_record.prev_day }
    amount                { 5489.97 }
    method_kind           { 'ach' }
    reference_id          { 'some_id' }
  end
end