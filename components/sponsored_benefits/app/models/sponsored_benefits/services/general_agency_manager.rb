module SponsoredBenefits
  module Services
    class GeneralAgencyManager
      include Acapi::Notifiers

      attr_accessor :form

      def initialize(form)
        @form = form
      end

      # Assign an agency to a list of organizations, also removing any current
      # assignments.
      #
      # @param start_on [DateTime] the start time for the new assignment
      # @return [Void]
      def assign_general_agency(start_on: Time.now)
        form.plan_design_organization_ids.each do |id|
          unless fire_previous_general_agency(id)
            map_failed_assignment_on_form(id)
            next
          end
          create_general_agency_account(
            id,
            broker_agency_profile.primary_broker_role.id,
            start_on,
            form.general_agency_profile_id,
            form.broker_agency_profile_id,
            true
          )
        end
      end

      def assign_default_general_agency(broker_agency_profile, ids=form.plan_design_organization_ids, start_on= TimeKeeper.datetime_of_record)
        return true if broker_agency_profile.default_general_agency_profile_id.blank?
        broker_role_id = broker_agency_profile.primary_broker_role.id
        ids.each do |id|
          next if plan_design_organization(id).active_general_agency_account.present?
          create_general_agency_account(id, broker_role_id, start_on, broker_agency_profile.default_general_agency_profile_id, broker_agency_profile.id)
        end
      end

      def fire_general_agency(ids=form.plan_design_organization_ids)
        ids.each do |id|
          plan_design_organization(id).general_agency_accounts.active.each do |account|
            account.terminate!
            employer_profile = account.plan_design_organization.employer_profile
            if employer_profile
              send_message({
                employer_profile: employer_profile,
                general_agency_profile: account.general_agency_profile,
                broker_agency_profile: account.broker_agency_profile,
                status: 'Terminate'
              })
              notify("acapi.info.events.employer.general_agent_terminated", {timestamp: Time.now.to_i, employer_id: employer_profile.hbx_id, event_name: "general_agent_terminated"})
            end
          end
        end
      end

      def set_default_general_agency
        prev_default_ga_id = current_default_ga.id if current_default_ga
        broker_agency_profile.default_general_agency_profile = general_agency_profile
        broker_agency_profile.save!
        notify("acapi.info.events.broker.default_ga_changed", {:broker_id => broker_agency_profile.primary_broker_role.hbx_id, :pre_default_ga_id => prev_default_ga_id.to_s}) if broker_agency_profile.primary_broker_role
      end

      def clear_default_general_agency
        prev_default_ga_id = current_default_ga.id if current_default_ga
        broker_agency_profile.default_general_agency_profile = nil
        broker_agency_profile.save!
        notify("acapi.info.events.broker.default_ga_changed", {:broker_id => broker_agency_profile.primary_broker_role.hbx_id, :pre_default_ga_id => prev_default_ga_id.to_s}) if broker_agency_profile.primary_broker_role
      end

      def fire_previous_general_agency(id)
        fire_general_agency([id])
      end

      def map_failed_assignment_on_form(id)
        form.errors.add(:general_agency, "Assignment Failed for #{plan_design_organization(id).legal_name}")
      end

      def agencies
        BenefitSponsors::Organizations::GeneralAgencyProfile.all
      end

      def plan_design_organization(id)
        # Don't say return @plan design organization if defined?
        SponsoredBenefits::Organizations::PlanDesignOrganization.find(id)
      end

      def broker_agency_profile(id=form.broker_agency_profile_id)
        return @broker_agency_profile if defined? @broker_agency_profile
        @broker_agency_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.find(id) || ::BrokerAgencyProfile.find(id)
      end

      def general_agency_profile(id=form.general_agency_profile_id)
        return @general_agency_profile if defined? @general_agency_profile
        @general_agency_profile = BenefitSponsors::Organizations::GeneralAgencyProfile.find(id) || ::GeneralAgencyProfile.find(id)
      end

      def current_default_ga
        broker_agency_profile.default_general_agency_profile rescue nil
      end

      def send_notice(opts={})
        begin
          # ShopNoticesNotifierJob.perform_later(opts[:modal_id].to_s, opts[:event], employer_profile_id: opts[:employer_profile_id].to_s)
        rescue Exception => e
          (Rails.logger.error {"Unable to deliver opts[:event] to General Agency ID: #{opts[:modal_id]} due to #{e}"}) unless Rails.env.test?
        end
      end

      def send_message(opts={})
        subject = "You are associated to #{opts[:employer_profile].legal_name}- #{opts[:general_agency_profile].legal_name} (#{opts[:status]})"
        body = "<br><p>Associated details<br>General Agency : #{opts[:general_agency_profile].legal_name}<br>Employer : #{opts[:employer_profile].legal_name}<br>Status : #{opts[:status]}</p>"
        secure_message(opts[:broker_agency_profile], opts[:general_agency_profile], subject, body)
        secure_message(opts[:broker_agency_profile], opts[:employer_profile], subject, body)
      end

      def secure_message(from_provider, to_provider, subject, body)
        message_params = {
          sender_id: from_provider.id,
          parent_message_id: to_provider.id,
          from: from_provider.legal_name,
          to: to_provider.legal_name,
          subject: subject,
          body: body
        }

        create_secure_message(message_params, to_provider, :inbox)
        create_secure_message(message_params, from_provider, :sent)
      end

      def create_secure_message(message_params, inbox_provider, folder)
        message = ::Message.new(message_params)
        message.folder = ::Message::FOLDER_TYPES[folder]
        msg_box = inbox_provider.inbox
        msg_box.post_message(message)
        msg_box.save
      end

      def dc?
        Settings.aca.state_abbreviation == "DC"
      end

      protected

      # rubocop:disable Metrics/ParameterLists

      # HACK: Little bit of slight of hand here.
      #       I have added another parameter, 'bump_timestamp', here.
      #       This allows the caller of the function to put another second
      #       The timestamp for when the general agency assignment event is
      #       fired.
      #       This is needed because:
      #         - certain downstream systems have issues if a General Agency
      #           Account termination event occurs simultaneously with an add
      #         - our timestamps lack sub-second resolution
      #
      #       Thus, I've added the ability to 'bump' the event timestamp when
      #       desired by the caller, so that one event can occur 'after' the
      #       other.
      #
      #       This impacts only the firing of the event - it has no impact on when
      #       the account is actually considered 'active' in the database.
      def create_general_agency_account(
        id,
        broker_role_id,
        start_on = Time.now,
        general_agency_profile_id = form.general_agency_profile_id,
        broker_agency_profile_id = form.broker_agency_profile_id,
        bump_timestamp = false
      )
        ts_bump = bump_timestamp ? 1 : 0
        timestamp = (Time.now + ts_bump.seconds).to_i
        plan_design_organization(id).general_agency_accounts.build(
          start_on: start_on,
          broker_role_id: broker_role_id
        ).tap do |account|
          account.general_agency_profile = general_agency_profile(general_agency_profile_id)
          account.broker_agency_profile = broker_agency_profile(broker_agency_profile_id)
          if account.save
            employer_profile = account.plan_design_organization.employer_profile
            if employer_profile
              send_message(
                {
                  employer_profile: employer_profile,
                  general_agency_profile: general_agency_profile(general_agency_profile_id),
                  broker_agency_profile: broker_agency_profile(broker_agency_profile_id),
                  status: 'Hire'
                }
              )
              notify(
                "acapi.info.events.employer.general_agent_added",
                {
                  employer_id: employer_profile.hbx_id,
                  event_name: "general_agent_added",
                  timestamp: timestamp
                }
              )
            end
          elsif form.present?
            map_failed_assignment_on_form(id)
          end
        end
      end

      # rubocop:enable Metrics/ParameterLists
    end
  end
end
