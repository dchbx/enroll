# frozen_string_literal: true

# Worker class to process bulk notice
class BulkNoticeWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster

  def perform(audience_id, bulk_notice_id)
    sleep 2
    @bulk_notice = Admin::BulkNotice.find(bulk_notice_id)
    @org = BenefitSponsors::Organizations::Organization.find(audience_id)
    params = {
      subject: @bulk_notice.subject,
      body: @bulk_notice.body,
      actions_id: "Bulk Notice",
      document: @bulk_notice.documents.first,
      model_id: @bulk_notice.id.to_s,
      model_klass: @bulk_notice.class.to_s
    }

    if @bulk_notice.audience_type == 'employee'
      #loop through each employee
      results = @org.census_employees.each do |employee|
        Operations::SecureMessageAction.new.call(
          params: params.merge({ resource_id: employee.employee_profile.person.id.to_s, resource_name: 'Person' })
        )
      end
      result = results.any?(&:success?)
    else
      # normal profile params here for other audience types
      result = Operations::SecureMessageAction.new.call(
        params: params.merge({ resource_id: @org.profiles.first.id.to_s, resource_name: 'BenefitSponsors::Organizations::Profile' })
      )
    end

    if result.success?
      @bulk_notice.results.create(
        audience_id: audience_id,
        result: "Success"
      )
    else
      @bulk_notice.results.create(
        audience_id: audience_id,
        result: "Error"
      )
      Rails.logger.error("Error processing #{audience_id} for Bulk Notice request #{bulk_notice_id}")
    end

    html = ApplicationController.render(partial: "exchanges/bulk_notices/summary_line", locals: { bulk_notice: @bulk_notice, id: audience_id, org: @org.attributes.symbolize_keys.slice(:id, :fein, :hbx_id, :legal_name) })
    cable_ready["bulk-notice-processing"].morph(
      selector: "#bulk-notice-#{@bulk_notice.id}-audience-#{audience_id}",
      html: html
    )
    cable_ready.broadcast

    Rails.logger.info("Processing #{audience_id} for Bulk Notice request #{bulk_notice_id}")
  end
end