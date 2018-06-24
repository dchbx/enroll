class ShopGeneralAgencyNotices::GeneralAgencyHiredNotice < ShopGeneralAgencyNotice

  attr_accessor :general_agency_profile, :employer_profile_id
  
  def initialize(general_agency_profile, args = {})
    self.employer_profile_id = args[:options][:employer_profile_id]
    super(general_agency_profile, args)
  end

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    employer_profile = EmployerProfile.find(self.employer_profile_id)
    employer_staff_name = employer_profile.staff_roles.first.full_name.titleize
    employer_legal_name = employer_profile.organization.legal_name
    broker_fullname = employer_profile.broker_agency_profile.primary_broker_role.person.full_name.titleize
    general_agency_account = employer_profile.active_general_agency_account
    
    notice.general_agency = PdfTemplates::GeneralAgencyNotice.new({
          :employer_fullname => employer_staff_name,
          :employer => employer_legal_name,
          :broker_fullname => broker_fullname,
          :general_agency_account_start_on => general_agency_account.start_on
        })
  end
end
