# frozen_string_literal: true

class IvlNotices::ConditionalEligibilityNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(hbx_enrollment_id, template_name = nil)
    template_obj = {}
    template_obj[:template] = (template_name || "notices/ivl/9f_conditional_eligibility_confirmation_notification.html.erb")
    super(PdfTemplates::ConditionalEligibilityNotice,template_obj)
    @hbx_enrollment_id = hbx_enrollment_id
    build
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
    append_enrollments(hbx_enrollments)
    append_individuals(hbx_enrollments)
  end
end