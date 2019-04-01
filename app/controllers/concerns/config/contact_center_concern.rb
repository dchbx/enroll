module Config::ContactCenterConcern
  def contact_center_phone_number
    Settings.contact_center.phone_number
  end
end
