# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_benefit_sponsorships_current_statement_activity, class: 'BenefitSponsors::BenefitSponsorships::CurrentStatementActivity' do
    description           { 'Payments' }
    name                  { 'Some Name' }
    type                  { 'payment_type' }
    posting_date          { TimeKeeper.date_of_record.prev_day }
    amount                { 5489.97 }
    coverage_month        { TimeKeeper.date_of_record.strftime('%B') }
    payment_method        { 'ach' }
    is_passive_renewal    { false }
  end
end