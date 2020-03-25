start_time = Time.now - 17.minutes
end_time = Time.now

class ShopEnrollmentsPublisher
  extend Acapi::Notifiers

  def self.publish_action(action_name, hbx_id, action)
    reply_to = "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler"

    notify(
      action_name, {
      :reply_to => reply_to,
      :hbx_enrollment_id => hbx_id,
      :enrollment_action_uri => action
    })
  end
end

enrollment_kinds = ["employer_sponsored", "employer_sponsored_cobra"]

purchase_ids = HbxEnrollment.collection.aggregate([
  {"$match" => {
    "workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_selected", "auto_renewing"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "kind" => {"$in" => enrollment_kinds},
    "sponsored_benefit_id" => {"$ne" => nil},
    "sponsored_benefit_package_id" => {"$ne" => nil}
  }},
  {"$group" => {"_id" => "$hbx_id"}}
]).map { |rec| rec["_id"] }

term_ids = HbxEnrollment.collection.aggregate([
  {"$match" => {
    "workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_terminated","coverage_canceled", "coverage_termination_pending"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "kind" => {"$in" => enrollment_kinds},
    "sponsored_benefit_id" => {"$ne" => nil},
    "sponsored_benefit_package_id" => {"$ne" => nil}
  }},
  {"$group" => {"_id" => "$hbx_id"}}
]).map { |rec| rec["_id"] }

def is_valid_benefit_application?(benefit_application)
  ["enrollment_eligible", "active", "terminated", "expired", "termination_pending"].include?(benefit_application.aasm_state.to_s)
end

def term_states
  %w(coverage_terminated coverage_canceled coverage_termination_pending)
end

def can_publish_enrollment?(enrollment, transition_at)
  sb = enrollment.sponsored_benefit
  benefit_application = sb.benefit_package.benefit_application
  quiet_period = benefit_application.enrollment_quiet_period
  if is_valid_benefit_application?(benefit_application)
    return false if transition_at.in_time_zone("UTC") <= quiet_period.max # don't transmit enrollments until quiet period ended
    return true  if term_states.include?(enrollment.aasm_state) # new hire enrollment check not needed for terminated enrollments
    return false if enrollment.new_hire_enrollment_for_shop? && (enrollment.effective_on <= (Time.now - 2.months))
    return true
  else
    return false
  end
end

puts purchase_ids.length unless Rails.env.test?
puts term_ids.length unless Rails.env.test?

Rails.logger.info "-----purchased families #{purchase_ids}"
purchase_ids.each do |hbx_id|
  purchase =  HbxEnrollment.where(hbx_id: hbx_id ).first
  purchased_at = purchase.workflow_state_transitions.where({
    "to_state" => {"$in" => ["coverage_selected", "auto_renewing"]},
    "transition_at" => {
      "$gte" => start_time,
      "$lt" => end_time
    }
  }).first.transition_at

    Rails.logger.info "---processing #{purchase.hbx_id}---#{purchased_at}---#{Time.now}"
  if can_publish_enrollment?(purchase, purchased_at)
    Rails.logger.info "-----publishing #{purchase.hbx_id}"
    ShopEnrollmentsPublisher.publish_action( "acapi.info.events.hbx_enrollment.coverage_selected",
                   purchase.hbx_id,
                   "urn:openhbx:terms:v1:enrollment#initial")
  end
end

term_ids.each do |hbx_id|
  term =  HbxEnrollment.where(hbx_id: hbx_id ).first
  terminated_at = term.workflow_state_transitions.where({
    "to_state" => {"$in" => term_states},
    "transition_at" => {
      "$gte" => start_time,
      "$lt" => end_time
    }
  }).first.transition_at
  Rails.logger.info "---processing termination #{term.hbx_id}---#{terminated_at}---#{Time.now}"
  if can_publish_enrollment?(term, terminated_at)
    Rails.logger.info "-----publishing termination #{term.hbx_id}"
    ShopEnrollmentsPublisher.publish_action( "acapi.info.events.hbx_enrollment.terminated",
                   term.hbx_id,
                   "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
  end
end
