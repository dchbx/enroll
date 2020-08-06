# frozen_string_literal: true

class IvlNotices::IvlTaxNotice < IvlNotice
  attr_accessor :family

  def initialize(consumer_role, args = {})
    @true_or_false = args[:options][:is_an_aqhp_hbx_enrollment]
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
    notice.is_an_aqhp_cover_letter = @true_or_false.present? && @true_or_false.to_s.downcase == "true" ? true : false
    notice.mpi_indicator = self.mpi_indicator
    family = recipient.primary_family
    notice.primary_fullname = ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end

  def append_address(_primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
                                                               street_1: "",
                                                               street_2: "",
                                                               city: "",
                                                               state: "",
                                                               zip: ""
                                                             })
  end
end