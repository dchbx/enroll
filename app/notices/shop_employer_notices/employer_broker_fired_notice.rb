class ShopEmployerNotices::EmployerBrokerFiredNotice < ShopEmployerNotice

  attr_accessor :employer_profile

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
    last_broker_agency_account = employer_profile.broker_agency_accounts.unscoped.select{|br| br.is_active ==  false}.sort_by(&:created_at).last
    broker_profile = last_broker_agency_account.broker_agency_profile
    broker_role = broker_profile.primary_broker_role
    person = broker_role.person
    notice.broker = PdfTemplates::Broker.new({
                       first_name: person.first_name,
                       last_name: person.last_name,
                       terminated_on: last_broker_agency_account.end_on,
                       organization: broker_profile.legal_name
                    })
  end

end
