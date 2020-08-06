# frozen_string_literal: true

class IvlNotices::EligibilityDenialNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(_consumer)
    super(PdfTemplates::ConditionalEligibilityNotice, {
      template: "notices/ivl/11_individual_total_ineligibility.html.erb"
    })
  end

  def build
    @hbx_enrollment = HbxEnrollment.find(@hbx_enrollment_id)
    @consumer = @hbx_enrollment.subscriber.person
    super
    @family = @consumer.primary_family
    hbx_enrollments = begin
                        @family.try(:latest_household).try(:hbx_enrollments).active
                      rescue StandardError
                        []
                      end
    append_individuals(hbx_enrollments)
  end
end