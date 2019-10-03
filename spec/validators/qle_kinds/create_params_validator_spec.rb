require "rails_helper"

describe QleKinds::CreateParamsValidator do

  subject { QleKinds::CreateParamsValidator.new }

  let(:valid_params) do
    ActionController::Parameters.new({
      "data" => {
        "title" => "a Title",
        "market_kind" => "fehb",
        "is_self_attested" => "Yes"
      }
    })
  end
  let(:valid_params_data_permitted) { valid_params.require("data").permit!.to_h }

  it "is valid" do
    expect(subject.call(valid_params_data_permitted).success?).to be_truthy
  end
end