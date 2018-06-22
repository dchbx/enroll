class ShopBrokerNotice < Notice

  Required= Notice::Required + []

  attr_accessor :broker
  attr_accessor :employer_profile

  def initialize(args = {})
    super(args)
  end

  def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'taglines.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
  end

  def append_address(address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
                                 street_1: address.address_1.titleize,
                                 street_2: address.address_2.titleize,
                                 city: address.city.titleize,
                                 state: address.state,
                                 zip: address.zip
                             })
  end

  def upload_and_send_secure_message
    doc_uri = upload_to_amazonS3
    notice = create_recipient_document(doc_uri)
    create_secure_inbox_message(notice)
  end

  def create_secure_inbox_message(notice)
    body = "<br>You can download the notice by clicking this link " +
        "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
                                                                                               recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: employer_profile.legal_name })
    message.save!
  end

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
                   url: "www.dhs.dc.gov",
                   phone: "(855) 532-5465",
                   fax: "(855) 532-5465",
                   email: "#{Settings.contact_center.email_address}"
               })
  end
end
