# frozen_string_literal: true

class IvlNotices::DocumentsVerification < IvlNotice

  attr_reader :notice

  def initialize(consumer, args = {})
    super(args)
    @consumer = consumer
    # @to = (@consumer.home_email || @consumer.work_email).address
    @template = args[:template] || "notices/ivl/documents_verification_reminder1.html.erb"
    build
  end

  def build
    @family = Family.find_by_primary_applicant(@consumer)
    @hbx_enrollments = begin
                         @family.try(:latest_household).try(:hbx_enrollments).active
                       rescue StandardError
                         []
                       end
    @notice = PdfTemplates::EligibilityNotice.new
    @notice.primary_fullname = @consumer.full_name.titleize
    @notice.primary_identifier = @consumer.hbx_id
    append_address(@consumer.addresses[0])
  end

  def append_address(primary_address)
    @notice.primary_address = PdfTemplates::NoticeAddress.new({
                                                                street_1: primary_address.address_1.titleize,
                                                                street_2: primary_address.address_2.titleize,
                                                                city: primary_address.city.titleize,
                                                                state: primary_address.state,
                                                                zip: primary_address.zip
                                                              })
  end
end
