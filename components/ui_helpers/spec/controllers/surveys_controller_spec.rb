require_relative '../rails_helper'

describe SurveysController, type: :controller do
  before { get :new }
  it 'exists' do
    expect(response.body).to_not be_nil
  end
end
