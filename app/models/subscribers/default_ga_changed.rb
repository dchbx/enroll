# frozen_string_literal: true

module Subscribers
  class DefaultGaChanged < ::Acapi::Subscription
    def self.subscription_details
      ["acapi.info.events.broker.default_ga_changed"]
    end

    def call(_event_name, _e_start, _e_end, _msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      hbx_id = stringed_key_payload["broker_id"]
      pre_default_ga_id = begin
                            BSON::ObjectId.from_string(stringed_key_payload["pre_default_ga_id"])
                          rescue StandardError
                            ""
                          end
      person = Person.by_hbx_id(hbx_id).last
      broker_agency_profile = begin
                                person.broker_role.broker_agency_profile
                              rescue StandardError
                                nil
                              end
      if broker_agency_profile.present?
        if broker_agency_profile.default_general_agency_profile_id.present?
          #change
          plan_design_organizations = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(broker_agency_profile.id)
          service.assign_default_general_agency(broker_agency_profile, plan_design_organizations.map(&:id))
        else
          #clear
          return if pre_default_ga_id.blank?

          plan_design_organizations = SponsoredBenefits::Organizations::PlanDesignOrganization.where(
            :owner_profile_id => BSON::ObjectId.from_string(broker_agency_profile.id),
            :general_agency_accounts => {
              :"$elemMatch" => {
                :aasm_state => :active,
                :benefit_sponsrship_general_agency_profile_id => BSON::ObjectId.from_string(pre_default_ga_id)
              }
            }
          )

          service.fire_general_agency(plan_design_organizations.map(&:id))
        end
      end
    rescue Exception => e
      log("GA_ERROR: Unable to set default ga for #{e.try(:message)}", {:severity => "error"})
    end

    def service
      return @service if defined? @service

      @service = SponsoredBenefits::Services::GeneralAgencyManager.new(nil)
    end
  end
end