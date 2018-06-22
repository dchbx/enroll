class ShopEmployeeNotices::EeSepRequestAcceptedNotice < ShopEmployeeNotice

  attr_accessor :census_employee

  def initialize(census_employee, args)
    @qle_on = args[:options][:qle_on]
    @end_on = args[:options][:end_on]
    @title = args[:options][:title]
    super(census_employee, args)
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
    notice.sep = PdfTemplates::SpecialEnrollmentPeriod.new({
      :qle_on => Date.strptime(@qle_on,"%m/%d/%Y"),
      :end_on => Date.strptime(@end_on,"%m/%d/%Y"),
      :title => @title
      })

  end
end
