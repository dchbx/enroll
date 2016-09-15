class Employers::InboxesController < InboxesController

  def new
    @row = params[:row]
    @inbox_to_name = params["to"]
    @inbox_provider_name = 'HBXAdmin'
    super
  end

  def find_inbox_provider
    @inbox_provider = EmployerProfile.find(params["id"])
    @inbox_provider_name = @inbox_provider.legal_name
  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end
end
