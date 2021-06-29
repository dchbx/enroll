# frozen_string_literal: true

module Config
  module ContactCenterConcern
    def contact_center_phone_number
      EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item
    end
  end
end
