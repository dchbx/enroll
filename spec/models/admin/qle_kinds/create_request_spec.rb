require "rails_helper"

describe Admin::QleKinds::CreateRequest do

  subject { Admin::QleKinds::CreateRequest }

  describe "given valid parameters" do

    let(:valid_params) do
      {
        :title => "a title",
        :market_kind => "shop",
        :is_self_attested => true
      }
    end

    it "creates successfully" do
      Admin::QleKinds::CreateRequest.new(valid_params)
    end

  end
end