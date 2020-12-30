# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_inbox, class: 'BenefitSponsors::Inboxes::Inbox' do
    trait :with_message do
      after(:create) do |i|
        create_list(:benefit_sponsors_message, 2, inbox: i)
      end
    end
  end
end
