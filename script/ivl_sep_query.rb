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

def is_retro_renewal_enrollment?(hbx_id)
  enrollment = HbxEnrollment.by_hbx_id(hbx_id).first
  return false unless enrollment.present?
  return false if enrollment.is_shop?
  last_date= enrollment.effective_on - 1
  active_enrollment = enrollment.family.hbx_enrollments.where(:kind => enrollment.kind,
                                          :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_termination_pending"]),
                                          :coverage_kind => enrollment.coverage_kind,
                                          :effective_on => { "$gte" => last_date.beginning_of_year, "$lt" => last_date}).first
  return false unless active_enrollment.present?
  return false unless active_enrollment.product.renewal_product == enrollment.product
  enrollment.workflow_state_transitions.where(from_state: 'auto_renewing', to_state: 'coverage_selected').present?
end

enrollment_kinds = %w(employer_sponsored employer_sponsored_cobra)
active_statuses = %w[coverage_selected auto_renewing renewing_coverage_selected]

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
    "created_at" => { "$last" =>  "$created_at" },
    "enrollment_state" => {"$last" => "$aasm_state"}
  }},
  {"$project" => {
    "_id" => 1,
    "created_at" => 1,
    "enrollment_state" => "$enrollment_state"
  }},
  { "$sort" => { "created_at" => 1 } }
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
  {"$group" => {
      "_id" => "$hbx_id",
      "created_at" => { "$last" =>  "$created_at" },
  }},
  { "$sort" => { "created_at" => 1 } }
])

puts purchases.count
puts terms.count

purchase_event = "acapi.info.events.hbx_enrollment.coverage_selected"
purchases.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"

  if rec["enrollment_state"] == 'auto_renewing' || is_retro_renewal_enrollment?(pol_id)
    puts "renewal enrollment #{pol_id}"
  else
    puts "initial enrollment #{pol_id}"
  end
end

term_event = "acapi.info.events.hbx_enrollment.terminated"
terms.each do |rec|
  pol_id = rec["_id"]
  Rails.logger.info "-----publishing #{pol_id}"
  IvlEnrollmentsPublisher.publish_action(term_event, pol_id, "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
end
