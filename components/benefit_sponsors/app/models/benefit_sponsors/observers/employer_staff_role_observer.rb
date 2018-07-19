module BenefitSponsors
  module Observers
    class EmployerStaffRoleObserver
      include Acapi::Notifiers
      extend Acapi::Notifiers

      def contact_changed?(changed_model, options={})
        case changed_model
        when EmployerStaffRole
          notify(
            "acapi.info.events.employer.contact_changed",
            {employer_id: changed_model.profile.hbx_id , event_name: "contact_changed"}
          ) if changed_model.changed?
        when Person
          changed_model.employer_staff_roles.each do |employer_staff_role|
            notify(
              "acapi.info.events.employer.contact_changed",
              {employer_id: employer_staff_role.profile.hbx_id , event_name: "contact_changed"}
            ) if employer_staff_role.changed?
          end
        end
      end
    end
  end
end
