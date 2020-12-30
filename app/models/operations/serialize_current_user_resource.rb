module Operations
  class SerializeCurrentUserResource
    def initialize(user)
      @user = user
    end

    def call
      user_data_hash = Hash.new
      account_name = @user.email.blank? ? @user.oim_id : @user.email
      user_data_hash[:account_name] = account_name
      permission_proxy = Admin::PermissionsProxy.new(@user)
      user_data_hash[:view_agency_staff] = permission_proxy.view_agency_staff
      user_data_hash[:manage_agency_staff] = permission_proxy.manage_agency_staff
      user_data_hash
    end
  end
end
