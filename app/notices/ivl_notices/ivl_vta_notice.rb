# frozen_string_literal: true

class IvlNotices::IvlVtaNotice < IvlNotice
  attr_accessor :family

  def initialize(consumer_role, args = {})
    @true_or_false = args[:options][:is_a_void_active_cover_letter]
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store] = consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.header = 'notices/shared/ivl_tax_header.html.erb'
    super(args)
  end

  def attach_1095a_form
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', '1095a.pdf')]
  end

  def deliver
    append_hbe
    build
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_non_discrimination
    attach_taglines
    attach_1095a_form
    upload_and_send_secure_message
    send_generic_notice_alert if recipient.consumer_role.can_receive_electronic_communication?
    store_paper_notice if recipient.consumer_role.can_receive_paper_communication?
  end

  def build
    notice.is_a_void_active_cover_letter = @true_or_false.present? && @true_or_false.to_s.downcase == 'true'
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_fullname = ''
    raise 'mailing address not present' unless recipient.mailing_address

    append_address(recipient.mailing_address)
  end

  def append_address(_primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({ street_1: '',
                                                               street_2: '',
                                                               city: '',
                                                               state: '',
                                                               zip: ''})
  end
end
