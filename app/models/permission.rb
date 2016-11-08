class Permission
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  
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
    def developer
      Permission.where(name: 'developer').first
    end
  end
end
