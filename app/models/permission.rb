class Permission
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  PERMISSION_KINDS = %w(hbx_staff hbx_read_only hbx_csr_supervisor hbx_csr_tier1 hbx_csr_tier2 hbx_tier3 developer super_admin)

  field :name, type: String

  field :modify_family, type: Boolean, default: false
  field :modify_employer, type: Boolean, default: false
  field :revert_application, type: Boolean, default: false
  field :list_enrollments, type: Boolean, default: false
  field :send_broker_agency_message, type: Boolean, default: false
  field :approve_broker, type: Boolean, default: false
  field :approve_ga, type: Boolean, default: false
  field :modify_admin_tabs, type: Boolean, default: false
  field :view_admin_tabs, type: Boolean, default: false
  field :can_update_ssn, type: Boolean, default: false
  field :can_complete_resident_application, type: Boolean, default: false
  field :can_add_sep, default: false
  field :can_add_pdc, default: false
  field :can_lock_unlock, type: Boolean, default: false
  field :can_view_username_and_email, type: Boolean, default: false
  field :can_transition_family_members, type: Boolean, default: false
  field :can_access_user_account_tab, type: Boolean, default: false
  field :view_login_history, type: Boolean, default: false

  field :can_reset_password, type: Boolean, default: false
  field :can_extend_open_enrollment, type: Boolean, default: false
  field :can_modify_plan_year, type: Boolean, default: false
  field :can_create_benefit_application, type: Boolean, default: false
  field :can_change_fein, type: Boolean, default: false
  field :can_force_publish, type: Boolean, default: false
  field :view_the_configuration_tab, type: Boolean, default: false
  field :can_submit_time_travel_request, type: Boolean, default: false
  field :can_view_application_types, type: Boolean, default: false
  field :view_personal_info_page, type: Boolean, default: false
  field :can_access_new_consumer_application_sub_tab, type: Boolean, default: false
  field :can_access_outstanding_verification_sub_tab, type: Boolean, default: false
  field :can_access_identity_verification_sub_tab, type: Boolean, default: false
  field :can_access_accept_reject_identity_documents, type: Boolean, default: false
  field :can_access_accept_reject_paper_application_documents, type: Boolean, default: false
  field :can_delete_identity_application_documents, type: Boolean, default: false
  field :can_access_pay_now, type: Boolean, default: false
  field :view_agency_staff, type: Boolean, default: false
  field :manage_agency_staff, type: Boolean, default: false
  field :can_send_secure_message, type: Boolean, default: false
  field :can_manage_qles, type: Boolean, default: false
  field :can_manage_settings, type: Boolean, default: false

  class << self
    def hbx_staff
      Permission.where(name: 'hbx_staff').first
    end
    def hbx_read_only
      Permission.where(name: 'hbx_read_only').first
    end
    def hbx_csr_supervisor
      Permission.where(name: 'hbx_csr_supervisor').first
    end
    def hbx_csr_tier1
      Permission.where(name: 'hbx_csr_tier1').first
    end
    def hbx_csr_tier2
      Permission.where(name: 'hbx_csr_tier2').first
    end
    def hbx_tier3
      Permission.where(name: 'hbx_tier3').first
    end
    def developer
      Permission.where(name: 'developer').first
    end
    def super_admin
      Permission.where(name: 'super_admin').first
    end
  end
end
