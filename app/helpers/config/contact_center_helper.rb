module Config::ContactCenterHelper
  def contact_center_address_one
    Settings.contact_center.mailing_address.address_1
  end

  def contact_center_alt_name
    Settings.contact_center.alt_name
  end

  def contact_center_alt_phone_number
    Settings.contact_center.alt_phone_number
  end

  def contact_center_alt_fax_number
    Settings.contact_center.alt_fax
  end

  def contact_center_ivl_number
    Settings.contact_center.ivl_number
  end

  def contact_center_city
    Settings.contact_center.mailing_address.city
  end

  def contact_center_email_address
    Settings.contact_center.email_address
  end

  def contact_center_phone_number
    Settings.contact_center.phone_number
  end

  def contact_center_ivl_phone_number
    Settings.contact_center.ivl_phone_number
  end

  def contact_center_fax_number
    Settings.contact_center.fax
  end

  def contact_center_postal_code
    Settings.contact_center.mailing_address.zip_code
  end

  def contact_center_name
    Settings.contact_center.name
  end

  def contact_center_mailing_address_name
    Settings.contact_center.mailing_address.name
  end

  def contact_center_state
    Settings.contact_center.mailing_address.state
  end

  def contact_center_tty_number
    Settings.contact_center.tty_number
  end

  def small_businesss_email
    Settings.contact_center.small_business_email
  end

  def small_business_email_link
    mail_to small_businesss_email,small_businesss_email
  end

  def contact_center_appeals
    Settings.contact_center.appeals
  end

  def contact_center_appeals_link
    link_to contact_center_appeals,contact_center_appeals
  end

  def contact_center_appeal_name
    Settings.contact_center.appeal_center.name
  end

  def contact_center_appeal_address_one
    Settings.contact_center.appeal_center.address_1
  end

  def contact_center_appeal_city
    Settings.contact_center.appeal_center.city
  end

  def contact_center_appeal_state
    Settings.contact_center.appeal_center.state
  end

  def contact_center_appeal_zip
    Settings.contact_center.appeal_center.zip_code
  end

  def non_discrimination_email
    Settings.contact_center.non_discrimination.email
  end

  def non_discrimination_phone_1
    Settings.contact_center.non_discrimination.phone_1
  end

  def non_discrimination_phone_2
    Settings.contact_center.non_discrimination.phone_2
  end

  def non_discrimination_phone_3
    Settings.contact_center.non_discrimination.phone_3
  end

  def non_discrimination_complaint_url
    Settings.contact_center.non_discrimination.complaint_url
  end

end
