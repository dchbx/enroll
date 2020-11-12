# frozen_string_literal: true

class BulkNoticeWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster

  def perform(audience_id, bulk_notice_id)
    sleep 2
    @bulk_notice = Admin::BulkNotice.find(bulk_notice_id)
    @org = BenefitSponsors::Organizations::Organization.find(audience_id)

    if @bulk_notice.audience_type == 'employee'
      #loop through each employee
      results = @org.census_employees.each do |employee|
        Operations::SecureMessageAction.new.call(
          params: {
            resource_id: employee.employee_profile.person.id,
            resource_name: 'Person',
            subject: @bulk_notice.subject,
            body: @bulk_notice.body,
            actions_id: "Bulk Notice",
            document: @bulk_notice.documents.first,
            model_id: @bulk_notice.id,
            model_klass: @bulk_notice.class.to_s
          },
          user: User.first
        )
      end
      result = results.any?(&:success?)
    else
      # normal profile params here for other audience types
      result = Operations::SecureMessageAction.new.call(
        params: {
          resource_id: @org.profiles.first.id.to_s,
          resource_name: 'BenefitSponsors::Organizations::Profile',
          subject: @bulk_notice.subject,
          body: @bulk_notice.body,
          actions_id: "Bulk Notice",
          document: @bulk_notice.documents.first,
          model_instance: @bulk_notice,
          model_klass: @bulk_notice.class.to_s
        },
        user: User.first
      )
    end
    if result.success?
      @bulk_notice.results.create(
        audience_id: audience_id,
        result: "Success"
      )

      html = ApplicationController.render(partial: "exchanges/bulk_notices/summary_line", locals: { bulk_notice: @bulk_notice, id: audience_id, org: @org.attributes.symbolize_keys.slice(:id, :fein, :hbx_id, :legal_name) })
      cable_ready["bulk-notice-processing"].morph(
        selector: "#bulk-notice-#{@bulk_notice.id}-audience-#{audience_id}",
        html: html
      )
      cable_ready.broadcast
    else
      @bulk_notice.results.create(
        audience_id: audience_id,
        result: "Error"
      )
    end
    Rails.logger.info("Processing #{audience_id} for Bulk Notice request #{bulk_notice_id}")
  end
end