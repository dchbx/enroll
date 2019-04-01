module Config::ContactCenterModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :contact_center_name, :to => :class
    delegate :contact_center_phone_number, :to => :class
  end

  class_methods do
    def contact_center_name
      @@contact_center_name ||= Settings.contact_center.name
    end

    def contact_center_phone_number
      @contact_center_phone_number ||= Settings.contact_center.phone_number
    end
  end
end
