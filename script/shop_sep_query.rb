start_time = Time.now - 17.minutes
end_time = Time.now

class ShopEnrollmentsPublisher
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

enrollment_kinds = ["employer_sponsored", "employer_sponsored_cobra"]

purchase_ids = Family.collection.aggregate([
  {"$match" => {
    "households.hbx_enrollments.workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_selected", "auto_renewing"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    }
  }},
  {"$unwind" => "$households"},
  {"$unwind" => "$households.hbx_enrollments"},
  {"$match" => {
    "households.hbx_enrollments.workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_selected", "auto_renewing"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "households.hbx_enrollments.kind" => {"$in" => enrollment_kinds}
  }},
  {"$group" => {"_id" => "$households.hbx_enrollments.hbx_id"}}
]).map { |rec| rec["_id"] }

term_ids = Family.collection.aggregate([
  {"$match" => {
    "households.hbx_enrollments.workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_terminated","coverage_canceled", "coverage_termination_pending"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    }
  }},
  {"$unwind" => "$households"},
  {"$unwind" => "$households.hbx_enrollments"},
  {"$match" => {
    "households.hbx_enrollments.workflow_state_transitions" => {
      "$elemMatch" => {
        "to_state" => {"$in" => ["coverage_terminated","coverage_canceled", "coverage_termination_pending"]},
        "transition_at" => {
           "$gte" => start_time,
           "$lt" => end_time
        }
      }
    },
    "households.hbx_enrollments.kind" => {"$in" => enrollment_kinds}
  }},
  {"$group" => {"_id" => "$households.hbx_enrollments.hbx_id"}}
]).map { |rec| rec["_id"] }

def quiet_period_enrollment?(plan_year, submitted_at)
  duration = (plan_year.is_renewing? ? 15 : 28)
  submitted_at.in_time_zone("UTC") < TimeKeeper.start_of_exchange_day_from_utc(plan_year.start_on.prev_month + duration.days)
end

def is_valid_plan_year?(plan_year)
  %w(enrolled renewing_enrolled canceled expired renewing_canceled active terminated termination_pending).include?(plan_year.aasm_state)
end

def term_states
  %w(coverage_terminated coverage_canceled coverage_termination_pending)
end

def can_publish_enrollment?(enrollment, transition_at)
  plan_year = enrollment.benefit_group.plan_year
  if enrollment.employer_profile.aasm_state == "enrolled" || is_valid_plan_year?(plan_year)
    return false if quiet_period_enrollment?(plan_year, transition_at) # don't transmit quiet period enrollment
    return true  if term_states.include?(enrollment.aasm_state) # new hire enrollment check not needed for terminated enrollments
    return false if enrollment.new_hire_enrollment_for_shop? && (enrollment.effective_on <= (Time.now - 2.months))
    return true
  else
    return false
  end
end

puts purchase_ids.length
puts term_ids.length

purchase_families = Family.where("households.hbx_enrollments.hbx_id" => {"$in" => purchase_ids})

Rails.logger.info "-----purchased families #{purchase_ids}"
purchase_families.each do |fam|
  purchases = fam.households.flat_map(&:hbx_enrollments).select { |en| purchase_ids.include?(en.hbx_id) }
  purchases.each do |purchase|
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
end

term_families = Family.where("households.hbx_enrollments.hbx_id" => {"$in" => term_ids})
term_families.each do |fam|
  terms = fam.households.flat_map(&:hbx_enrollments).select { |en| term_ids.include?(en.hbx_id) }
  terms.each do |term|
    terminated_at = term.workflow_state_transitions.where({
      "to_state" => {"$in" => term_states},
      "transition_at" => {
        "$gte" => start_time,
        "$lt" => end_time
      }
    }).first.transition_at

    if can_publish_enrollment?(term, terminated_at)
      ShopEnrollmentsPublisher.publish_action( "acapi.info.events.hbx_enrollment.terminated",
                     term.hbx_id,
                     "urn:openhbx:terms:v1:enrollment#terminate_enrollment")
    end
  end
end