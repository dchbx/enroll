# frozen_string_literal: true

FactoryBot.define do
  factory :rating_factor_entry do
    factor_key { 'a_key' }
    factor_value { 1.0 }
  end
end
