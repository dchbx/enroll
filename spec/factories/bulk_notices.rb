# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_notice, class: 'Admin::BulkNotice' do
    user_id { "john@doe" }
    audience_type { "Employer" }
    user
  end
end
