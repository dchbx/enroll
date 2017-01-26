require 'httparty'

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
    HTTParty.post(
      @config['forgerock']['url'],
      :body => json_data,
      :headers => headers
    )
  end

  def create_forgerock_account
    if Rails.env.production?
      response = make_create_request
      if response.has_key?("code") # error is present
      else
        @user.forgerock_uuid = response["_id"]
        @user.save
      end
      response
    end
  end

  def query
    {
      "_action" => "patch",
      "_queryId" => "for-userName",
      "uid" => @user_name,
    }
  end

  def json_patch_data
    data = []
    input_hash = {"mail" => @email, 'statusFlag' => @status_flag,
      'sn' => @last_name, 'givenName' => @first_name, 'userType' => @account_role}

    input_hash.each do |key, value|
      if value.present?
        data <<  {operation: "replace", field: key, value: value}
      end
    end
    data.to_json
  end

  def make_update_request
    load_forgerock_config
    HTTParty.post(
      @config['forgerock']['url'],
      :query => query,
      :body => json_patch_data,
      :headers => headers
    )
  end

  def update_forgerock_account
    if Rails.env.production?
      response = make_update_request
      if response.has_key?("code") # what to do here?
      else
      end
      response
    end
  end

end