# frozen_string_literal: true

# Worker class to process bulk notice
class BulkNoticeWorker
  include Sidekiq::Worker
  include CableReady::Broadcaster

  def perform(audience_id, bulk_notice_id) # rubocop:disable Metrics/AbcSize
    sleep 2

    @bulk_notice = Admin::BulkNotice.find(bulk_notice_id)
    @entity = BenefitSponsors::Organizations::Organization.where(_id: audience_id) ||
      Person.find(_id: audience_id)

    params = fetch_params(@bulk_notice)

    if @bulk_notice.audience_type == 'employee'
      #loop through each employee
      results = @entity.employer_profile.census_employees.each do |census_employee|
        Operations::SecureMessageAction.new.call(
          params: params.merge({ resource_id: census_employee.employee_role&.person&.id&.to_s, resource_name: 'Person' }),
          user: @bulk_notice.user
        )
      end
      result = results.any?(&:success?)
    elsif @bulk_notice.audience_type == 'consumer' || @bulk_notice.audience_type == 'resident' || @bulk_notice.audience_type == 'census_employee'
      resource = @entity
      result = Operations::SecureMessageAction.new.call(
        params: params.merge({ resource_id: resource&.id&.to_s, resource_name: resource&.class&.to_s }),
        user: @bulk_notice.user
      )
    else
      # normal profile params here for other audience types
      resource = fetch_resource(@entity, @bulk_notice.audience_type)
      result = Operations::SecureMessageAction.new.call(
        params: params.merge({ resource_id: resource&.id&.to_s, resource_name: resource&.class&.to_s }),
        user: @bulk_notice.user
      )
    end

    Rails.logger.error("Error processing #{audience_id} for Bulk Notice request #{bulk_notice_id}") unless result.success?

    @bulk_notice.results.create(
      audience_id: audience_id,
      result: result.success? ? 'Success' : 'Error'
    )

    html = ApplicationController.render(partial: "exchanges/bulk_notices/summary_line", locals: { bulk_notice: @bulk_notice, id: audience_id, org: @entity.attributes.symbolize_keys.slice(:id, :fein, :hbx_id, :legal_name) })
    cable_ready["bulk-notice-processing"].morph(
      selector: "#bulk-notice-#{@bulk_notice.id}-audience-#{audience_id}",
      html: html
    )
    cable_ready.broadcast

    Rails.logger.info("Processing #{audience_id} for Bulk Notice request #{bulk_notice_id}")
  end

  def fetch_params(bulk_notice)
    {
      subject: bulk_notice.subject,
      body: bulk_notice.body,
      actions_id: "Bulk Notice",
      document: bulk_notice.documents.first,
      model_id: bulk_notice.id.to_s,
      model_klass: bulk_notice.class.to_s
    }
  end

  def fetch_resource(org, profile_type)
    org.send("#{profile_type}_profile") if org && ['employer', 'broker_agency', 'general_agency'].include?(profile_type)
  end
end