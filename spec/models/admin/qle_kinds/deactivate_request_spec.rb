require "rails_helper"

describe Admin::QleKinds::DeactivateRequest do
  describe "given valid parameters" do
    let(:valid_params) do
      {
        :end_on => "01/01/2020",
      }
    end

    it "creates successfully" do
      Admin::QleKinds::DeactivateRequest.new(valid_params)
    end
  end
end
