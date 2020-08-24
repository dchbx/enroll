# frozen_string_literal: true

FactoryBot.define do
  factory :carrier_profile do
    organization  { FactoryBot.create(:organization, legal_name: "BMC HealthNet Plan", dba: "BMC HealthNet Plan") }
    abbrev        { "UHIC" }
    offers_sole_source { false }
    sequence(:issuer_hios_ids) { |n| [(11_111 + n).to_s] }

    transient do
      with_service_areas { 1 }
    end

    after(:create) do |carrier_profile, evaluator|
      unless evaluator.with_service_areas == 0
        carrier_profile.issuer_hios_ids.each do |hios_id|
          create(:carrier_service_area, issuer_hios_id: hios_id)
          create(:carrier_service_area, issuer_hios_id: hios_id, active_year: TimeKeeper.date_of_record.year + 1)
        end
      end
      create(:composite_rating_tier_factor_set, carrier_profile: carrier_profile)
    end
  end
end
