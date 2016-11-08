class HandleCoverageSelected
  include Interactor
  include Acapi::Notifiers

  def call
    enrollment = context.hbx_enrollment
    if !enrollment.is_shop?
      enrollment.hbx_enrollment_members.each do |hem|
        hem.ivl_coverage_selected
      end
      notify(HbxEnrollment::ENROLLMENT_CREATED_EVENT_NAME, {policy_id: enrollment.hbx_id})
      enrollment.update_attributes!(:published_to_bus_at => Time.now)
    elsif enrollment.is_shop_sep?
      notify(HbxEnrollment::ENROLLMENT_CREATED_EVENT_NAME, {policy_id: enrollment.hbx_id})
      enrollment.update_attributes!(:published_to_bus_at => Time.now)
    end
  end
end
