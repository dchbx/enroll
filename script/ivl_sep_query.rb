start_time = Time.now - 17.minutes
end_time = Time.now

class IvlEnrollmentsPublisher
  extend Acapi::Notifiers

  def self.publish_action(action_name, hbx_id, action)
    reply_to = "dc0.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"

    notify(
      action_name, {
      :reply_to => reply_to,
      :hbx_enrollment_id => hbx_id,
      :enrollment_action_uri => action
    })
  end
end

enrollment_kinds = %w(employer_sponsored employer_sponsored_cobra)
active_statuses = %w[coverage_selected auto_renewing unverified]

purchases = HbxEnrollment.collection.aggregate([
  {"$match" => {
    "workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => active_statuses},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "kind" => {"$nin" => enrollment_kinds}
  }},
  {"$group" => {
    "_id" => "$hbx_id",
    "enrollment_state" => {"$last" => "$aasm_state"}
  }},
  {"$project" => {
    "_id" => 1,
    "enrollment_state" => "$enrollment_state"
  }}
])

terms = HbxEnrollment.collection.aggregate([
  {"$match" => {
    "workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_terminated","coverage_canceled"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "kind" => {"$nin" => enrollment_kinds}
  }},
  {"$group" => {"_id" => "$hbx_id"}}
])

puts purchases.count
puts terms.count

purchase_event = "acapi.info.events.hbx_enrollment.coverage_selected"
purchases.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"

  if rec["enrollment_state"] == 'auto_renewing'
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#auto_renew")
  else
    IvlEnrollmentsPublisher.publish_action(purchase_event, pol_id, "urn:openhbx:terms:v1:enrollment#initial")
  end
end

term_event = "acapi.info.events.hbx_enrollment.terminated"
terms.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"
  IvlEnrollmentsPublisher.publish_action(term_event, pol_id, "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
end
