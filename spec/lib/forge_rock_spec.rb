require 'rails_helper'

describe ForgeRock do

  let(:person) { FactoryGirl.create(:person) }
  let(:user){ FactoryGirl.create(:user, person: person) }

  let(:success_params){
    {
      "_id"=> "11111111-1111-1111-1111-111111111111",
      "mail"=> user.email,
      "userName"=> user.oim_id,
      "sn"=> person.last_name,
      "givenName"=> person.first_name,
      "statusFlag"=> "1",
      "userType"=> "employee",
      "accountStatus"=>"active",
      "effectiveRoles"=>[],
      "effectiveAssignments"=>[]
   }
  }

  context "create request" do
    let(:create_request_params){
      {
        :email => user.email,
        :username => user.oim_id,
        :password => user.password,
        :first_name => person.first_name,
        :last_name => person.last_name,
        :account_role => "individual",
        :system_flag => "1"
      }
    }

    it "should return success response with valid parameters" do
      @forge_rock_object = ForgeRock.new(create_request_params, user)
      allow_any_instance_of(ForgeRock).to receive(:make_create_request).and_return(success_params)
      expect(@forge_rock_object.create_forgerock_account).to eq(success_params)
      expect(user.forgerock_uuid).to eq(success_params["_id"])
    end

  end

  context "update request" do

    let(:update_request_params){
      { email: user.email, user_name: user.oim_id, system_flag: "1" }
    }

    let(:error_params){
      {
        code: 400,
        reason: "Bad Request",
        message: "cannot have email as nil"
      }
    }

    it "should return success response with valid parameters" do
      @forge_rock_object = ForgeRock.new(update_request_params, user)
      allow_any_instance_of(ForgeRock).to receive(:make_update_request).and_return(success_params)
      expect(@forge_rock_object.update_forgerock_account).to eq(success_params)
    end

    it "should return error response with invalid parameters" do
      @forge_rock_object = ForgeRock.new(update_request_params.deep_merge!({email: ""}), user)
      allow_any_instance_of(ForgeRock).to receive(:make_update_request).and_return(error_params)
      expect(@forge_rock_object.update_forgerock_account).to eq(error_params)
    end

  end
end