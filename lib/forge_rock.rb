require 'httparty'
require 'pry-byebug'

class ForgeRock

  def initialize(attributes={}, user)
    @config = YAML.load_file("#{Rails.root}/config/forgerock.yml")
    @user = user
    @email = attributes[:email]
    @first_name = attributes[:first_name]
    @last_name = attributes[:last_name]
    @user_name = attributes[:username]
    @password = attributes[:password]
    @account_role = attributes[:account_role]
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
      'userType' => @account_role.try(:downcase)
    }.to_json
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'X-OpenIDM-Username' => @config['forgerock']['username'],
      'X-OpenIDM-Password' => @config['forgerock']['password'],
    }
  end

  def make_create_request
    HTTParty.post(
      @config['forgerock']['url'],
      :body => json_data,
      :headers => headers
    )
  end

  def create_forgerock_account
    response = make_create_request
    if response.has_key?("code") # error is present
    else
      @user.forgerock_uuid = response["_id"]
      @user.save
    end
    response
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
    input_hash = {"mail" => @email, 'statusFlag' => @status_flag}

    input_hash.each do |key, value|
      data <<  {operation: "replace", field: key, value: value}
    end
    data.to_json
  end

  def make_update_request
    HTTParty.post(
      @config['forgerock']['url'],
      :query => query,
      :body => json_patch_data,
      :headers => headers
    )
  end

  def update_forgerock_account
    response = make_update_request
    if response.has_key?("code") # what to do here?
    else
    end
    response
  end

end