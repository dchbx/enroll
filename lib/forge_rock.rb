require 'faraday'

class ForgeRock

  def initialize(attributes={}, user)
    @user = user
    @email = attributes[:email]
    @first_name = attributes[:first_name]
    @last_name = attributes[:last_name]
    @user_name = attributes[:username].try(:downcase)
    @password = attributes[:password]
    @account_role = attributes[:account_role].try(:downcase)
    @status_flag = attributes[:system_flag]
  end

  def json_data
    {
      'mail'  =>  @email,
      'sn'    =>  @last_name,
      'userName'  => @user_name,
      'password' => @password,
      'givenName' => @first_name,
      'statusFlag' => @status_flag,
      'userType' => @account_role
    }.to_json
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'X-OpenIDM-Username' => @config['forgerock']['username'],
      'X-OpenIDM-Password' => @config['forgerock']['password'],
    }
  end

  def load_forgerock_config
    @config = YAML.load_file("#{Rails.root}/config/forgerock.yml")
  end

  def make_create_request
    load_forgerock_config
    if Rails.env.production?
      Faraday.post do |request|
        request.url @config['forgerock']['url']
        request.headers = headers
        request.body = json_data
      end
    end
  end

  def create_forgerock_account
    response = make_create_request
    return if response.nil?
    if response.has_key?("code") # error is present
    else
      @user.forgerock_uuid = response["_id"]
      @user.save
    end
    response
  end

  def query_params
    {
      "_action" => "patch",
      "_queryId" => "for-userName",
      "uid" => @user_name,
    }
  end

  def json_patch_data
    data = []

    input_hash = {
      'givenName' => @first_name,
      'sn' => @last_name,
      'mail' => @email,
      'userType' => @account_role,
      'statusFlag' => @status_flag
    }

    input_hash.each do |key, value|
      if value.present?
        data <<  {operation: "replace", field: key, value: value}
      end
    end
    data.to_json
  end

  def make_update_request
    load_forgerock_config

    if Rails.env.production?
      Faraday.post do |request|
        request.url @config['forgerock']['url']
        request.headers = headers
        request.params = query_params
        request.body = json_patch_data
      end
    end
  end

  def update_forgerock_account
    response = make_update_request
    return if response.nil?
    if response.has_key?("code") # what to do here?
    else
    end
    response
  end

end