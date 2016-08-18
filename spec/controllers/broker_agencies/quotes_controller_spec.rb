require 'rails_helper'

RSpec.describe BrokerAgencies::QuotesController, type: :controller do
  let(:person){create(:person , :with_broker_role)}
  let(:user){create(:user, person: person)}
  let(:quote){create :quote , :with_household_and_members}
  let(:quote_benefit_group){build_stubbed :quote_benefit_group}
  let(:quote_attributes){FactoryGirl.attributes_for(:quote)}
  let(:quote_household_attributes){FactoryGirl.attributes_for(:quote_household)}
  let(:quote_member_attributes){FactoryGirl.attributes_for(:quote_member)}

  before do
    sign_in user
  end

  describe "Create"  do

    before do
      allow(user).to receive_message_chain(:person,:broker_role,:id){person.broker_role.id}
      allow(user).to receive(:has_broker_role?){true}
    end
    context "with valid quote params" do
      it "should save quote" do
        expect{
        post :create , broker_role_id: person.broker_role.id , quote: quote_attributes
        }.to change(Quote,:count).by(1)
      end
      it "should redirect to edit page" do
        post :create ,  broker_role_id: person.broker_role.id , quote: quote_attributes
        expect(assigns(:quote)).to be_a(Quote)
        expect(response).to redirect_to(edit_broker_agencies_broker_role_quote_path(person.broker_role.id,assigns(:quote).id))
      end
    end
    context "with valid quote params and nested quote household and member" do
      before do
        quote_household_attributes["quote_members_attributes"] ={ "0" => quote_member_attributes }
        quote_attributes["quote_benefit_groups_attributes"] = {"0"=>{"title"=>"Default Benefit Package"}}
        quote_attributes["quote_households_attributes"] = { "0" => quote_household_attributes }
      end
      it "should save quote" do
        expect{
          post :create ,  broker_role_id: person.broker_role.id , quote: quote_attributes
          }.to change(Quote,:count).by(1)
      end
      it "should save household info" do
        post :create, broker_role_id: person.broker_role.id , quote: quote_attributes
        expect(assigns(:quote)).to be_a(Quote)
        expect(assigns(:quote).quote_households.size).to eq 1
        expect(assigns(:quote).quote_households.first.family_id).to eq quote_household_attributes[:family_id]
      end
      it "should save household member attributes" do
        post :create, broker_role_id: person.broker_role.id , quote: quote_attributes
        expect(assigns(:quote)).to be_a(Quote)
        expect(assigns(:quote).quote_households.size).to eq 1
        expect(assigns(:quote).quote_households.first.quote_members.first.first_name).to eq quote_member_attributes[:first_name]
      end
    end
  end

  describe "Update" do
    before do
      @quote = FactoryGirl.create(:quote,:with_household_and_members)
    end

    context "update quote name" do
      before do
        put :update, broker_role_id: person.broker_role.id, :id => @quote.id  , quote: quote_attributes.merge!({quote_name: "New Name"})
        @quote.reload
      end
      it "should update quote name" do
        expect(@quote.quote_name).to eq "New Name"
      end
      it "should redirect to edit page" do
        expect(response).to redirect_to(edit_broker_agencies_broker_role_quote_path(person.broker_role.id,@quote.id))
      end
    end

    context "update quote start on date" do
      before do
        put :update, broker_role_id: person.broker_role.id, :id => @quote.id  , quote: quote_attributes.merge!({start_on: "2016-09-06"})
        @quote.reload
      end
      it "should update quote name" do
        expect(@quote.start_on.strftime("%Y-%m-%d")).to eq "2016-09-06"
      end
      it "should redirect to edit page" do
        expect(response).to redirect_to(edit_broker_agencies_broker_role_quote_path(person.broker_role.id,@quote.id))
      end
    end

    context "update quote member name and dob" do
      before do
        quote_household_attributes.merge!("id" => @quote.quote_households.first.id, "quote_members_attributes" => { "0" => {"first_name" =>"Thomas",
                "middle_name"=>"M" , "dob" => "07/04/1990", "id" => @quote.quote_households.first.quote_members.first.id } })
        quote_attributes[:quote_benefit_groups_attributes] = {"0"=>{"title"=>"Default Benefit Package"}}
        quote_attributes[:quote_households_attributes] = {"0" => quote_household_attributes }
        put :update, broker_role_id: person.broker_role.id, :id => @quote.id  , quote: quote_attributes
        @quote.reload
      end
      it "should update quote member first name" do
        expect(@quote.quote_households.first.quote_members.count).to eq 1
        expect(@quote.quote_households.first.quote_members.first.first_name).to eq "Thomas"
      end
      it "should update quote member dob" do
        expect(@quote.quote_households.first.quote_members.count).to eq 1
        expect(@quote.quote_households.first.quote_members.first.dob.strftime("%Y/%m/%d")).to eq "1990/07/04"
      end
      it "should redirect to edit page" do
        expect(response).to redirect_to(edit_broker_agencies_broker_role_quote_path(person.broker_role.id,@quote.id))
      end
    end
  end

  describe "Delete" do
    before do
      @quote = FactoryGirl.create(:quote,:with_household_and_members)
    end
    context "#delete_quote" do
      it "should delete quote" do
        expect{
          delete :delete_quote,  broker_role_id: person.broker_role.id , :id => @quote.id
          }.to change(Quote,:count).by(-1)
      end

      it "should redirect to my quote index page" do
        delete :delete_quote, broker_role_id: person.broker_role.id, :id => @quote.id
        expect(response).to redirect_to(my_quotes_broker_agencies_broker_role_quotes_path)
      end
    end

    context "#delete_household" do
      it "should delete quote household" do
        xhr :delete , :delete_household,   broker_role_id: person.broker_role.id, :id => @quote.id , :household_id => @quote.quote_households.first.id
        @quote.reload
        expect(@quote.quote_households).to eq []
      end
    end

    context "#delete_member" do
      it "should delete quote member" do
        xhr :delete , :delete_member, :id => @quote.id , broker_role_id: person.broker_role.id,
                                      :household_id => @quote.quote_households.first.id,
                                      :member_id =>  @quote.quote_households.first.quote_members.first.id
        @quote.reload
        expect(@quote.quote_households.first.quote_members).to eq []
      end
    end
  end

end