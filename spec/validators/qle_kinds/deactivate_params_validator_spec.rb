require "rails_helper"

describe QleKinds::DeactivateParamsValidator do

  subject { QleKinds::DeactivateParamsValidator.new }

  let(:valid_params) do
    ActionController::Parameters.new(
      {
        "data" => {
          "end_on" => "a Title"
        }
      }
    )
  end
  let(:invalid_params) do
    ActionController::Parameters.new(
      {
        "data" => {
          "end_on" => nil
        }
      }
    )
  end
  let(:valid_params_data_permitted) { valid_params.require("data").permit!.to_h }
  let(:invalid_params_permitted) { invalid_params.require("data").permit!.to_h }

  it "is valid" do
    expect(subject.call(valid_params_data_permitted).success?).to be_truthy
  end

  it "is invalid without end_on" do
    expect(subject.call(invalid_params_permitted).success?).to eq(false)
  end
end
