require "rails_helper"

describe Importers::ConversionEmployeeDelete do

  it "should be invalid - deletes are not allowed" do
    expect(subject.valid?).to be_falsey
  end

end
