require "rails_helper"
if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
require "tasks/iam_black_list/black_list"

def persisted(object)
  object.class.find(object.id)
end

describe BlackList, :dbclean => :after_each do
  context ".from_row" do
    let(:first_name) {"Sugar"}
    let(:last_name) {"Daddy"}
    let(:login) {"my_login"}
    let(:email) {"my_email@example.com"}
    let(:type) {"consumer"}
    let(:row) {[first_name, last_name, login, email, type]}
    let(:black_list_item) { BlackList.from_row(row) }

    it "should have the right first name" do
      expect(black_list_item.first_name).to eq first_name
    end

    it "should have the right last name" do
      expect(black_list_item.last_name).to eq last_name
    end

    it "should have the right login" do
      expect(black_list_item.login).to eq login
    end

    it "should have the right email" do
      expect(black_list_item.email).to eq email
    end

    it "should have the right type" do
      expect(black_list_item.type).to eq type
    end
  end

  context "when curam user exists with an email" do
    let!(:curam_user) do
      cu = CuramUser.new(username: "bobafett", first_name: "John", last_name: "Smyth", dob: "12/1/1972", email: "silly@example.com")
      cu.save
      cu
    end

    context "when black list item has an email" do
      let(:black_list_item) do
        item = BlackList.new()
        item.first_name = "John"
        item.last_name = "Smyth"
        item.login = curam_user.username
        item.type = "consumer"
        item.email = "foobar@example.com"
        item
      end

      before do
        @before_curam_user_count = CuramUser.count
        black_list_item.update_or_create_curam_user
      end

      it "should have created a new curam user" do
        expect(CuramUser.count).to eq @before_curam_user_count + 1
      end

      it "should be possible to find the new curam user by email" do
        expect(CuramUser.match_email(black_list_item.email).first).to be
      end
    end
  end

  context "when curam user exists with no email" do
    let!(:curam_user) do
      cu = CuramUser.new(username: "bobafett", first_name: "John", last_name: "Smyth", dob: "12/1/1972")
      cu.save
      cu
    end

    context "when black list item has no email" do
      let(:black_list_item) do
        item = BlackList.new()
        item.first_name = "John"
        item.last_name = "Smyth"
        item.login = curam_user.username
        item.type = "consumer"
        item
      end

      before do
        @before_curam_user_count = CuramUser.count
        black_list_item.update_or_create_curam_user
      end

      it "should not have created a new curam user" do
        expect(CuramUser.count).to eq @before_curam_user_count
      end

      it "should not have changed the curam user email" do
        expect(persisted(curam_user).email).to eq curam_user.email
      end
    end

    context "when black list item has an email" do
      let(:black_list_item) do
        item = BlackList.new()
        item.first_name = "John"
        item.last_name = "Smyth"
        item.login = curam_user.username
        item.type = "consumer"
        item.email = "foobar@example.com"
        item
      end

      before do
        @before_curam_user_count = CuramUser.count
        black_list_item.update_or_create_curam_user
      end

      it "should not have created a new curam user" do
        expect(CuramUser.count).to eq @before_curam_user_count
      end

      it "should have changed the curam user email" do
        expect(persisted(curam_user).email).to eq black_list_item.email
      end
    end
  end

  context "when curam user does not exist" do

    context "when black list item has an email" do
      let(:black_list_item) do
        item = BlackList.new()
        item.first_name = "John"
        item.last_name = "Smyth"
        item.login = "foobar"
        item.type = "consumer"
        item.email = "foobar@example.com"
        item
      end

      before do
        @before_curam_user_count = CuramUser.count
        black_list_item.update_or_create_curam_user
      end

      it "should have created a new curam user" do
        expect(CuramUser.count).to eq @before_curam_user_count + 1
      end

      it "should be possible to find the new curam user by email" do
        expect(CuramUser.match_email(black_list_item.email).first).to be
      end
    end

  end
end
end
