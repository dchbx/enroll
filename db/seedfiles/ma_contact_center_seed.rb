# Provide a benefit Market in which to attach Contact Center Settings
def create_contact_center_for(benefit_market)
  if benefit_market.instance_of? BenefitMarkets::BenefitMarket
    contact_center = benefit_market.contact_center_setting
    contact_center.name = "MA Customer Care Center"
    contact_center.alt_name = "MA CCC"

    contact_center.phones.build(:area_code => 855, :number => "5325465", :full_phone_number => "1-855-532-5465", :kind => "main")
    contact_center.phones.build(:area_code => 617, :number => "7224033", :full_phone_number => "1-617-722-4033", :kind => "fax")

    contact_center.addresses.build(
      :kind => "mailing",
      :address_1 => "PO Box 780833",
      :city => "Boston",
      :state => "MA",
      :zip => "19178")

    contact_center.emails.build(
      :kind => "work",
      :address => "info@state.ma.us")

    contact_center.save!
  end
end
