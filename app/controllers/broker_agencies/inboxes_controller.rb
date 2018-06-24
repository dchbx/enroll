class BrokerAgencies::InboxesController < InboxesController
  include Acapi::Notifiers

  def new
    @inbox_provider_name = 'HBX Admin.'
    @inbox_to_name = @broker_agency_provider.try(:legal_name)
    @inbox_provider = @broker_agency_provider
    super
  end

  def msg_to_portal
    @broker_agency_provider = BrokerAgencyProfile.find(params["inbox_id"])
    @inbox_provider = @broker_agency_provider
    @inbox_provider_name = @inbox_provider.try(:legal_name) 
    @inbox_to_name = "HBX Admin"
    log("#3969 and #3985 params: #{params.to_s}, request: #{request.env.inspect}", {:severity => "error"}) if @inbox_provider.blank?
    @new_message = @inbox_provider.inbox.messages.build
  end

  def create
    if params['message']['to'] != 'HBX Admin'
      super
    else
      @new_message.folder = Message::FOLDER_TYPES[:sent]
      inbox_message = @new_message.dup
      inbox_message.folder = Message::FOLDER_TYPES[:inbox]
      to_inbox = @profile.inbox
      to_inbox.post_message(inbox_message)
      @inbox.post_message(@new_message)
      if @inbox.save && to_inbox.save
        flash[:notice] = "Successfully sent message."
        redirect_to broker_agencies_profile_path(id: params['id'])
      else
        render "new"
      end
    end
  end

  def destroy
    @sent_box = true
    super
  end

  def show
    @sent_box = true
    super
  end

 def find_inbox_provider
    id = params["id"]||params['profile_id']
    if Person.find(params["id"]).id.to_s == id
      @inbox_provider = Person.find(params["id"])
    else
      @broker_agency_provider = BrokerAgencyProfile.where(:_id => params["id"]||params['profile_id'])
      if @broker_agency_provider.present?
        @inbox_provider = @broker_agency_provider
      else
        @inbox_provider = Person.where(:_id => id).first
      end

    end

  end

  def successful_save_path
    exchanges_hbx_profiles_root_path
  end

end
