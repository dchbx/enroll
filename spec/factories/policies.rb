FactoryBot.define do
  factory :policy do
    hbx_id { '1234567' }
    premium_total_in_cents { '66666.66' }
    total_responsible_amount { '111.11' }
    carrier_to_bill { true }
    effective_on { TimeKeeper.date_of_record }
  end
end
