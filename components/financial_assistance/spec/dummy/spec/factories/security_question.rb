# frozen_string_literal: true

FactoryBot.define do
  factory :security_question do
    title { 'First security question' }
    visible { true }
  end
end
