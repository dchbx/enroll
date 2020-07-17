require "rails_helper"

describe 'workflow/step' do
  let(:model) { double }
  let(:step) do
    UIHelpers::Workflow::Step.new model, 1, []
  end

  before do
    assign :current_step, step
    assign :model, model
    render
  end

  it 'renders' do
    expect(rendered).to_not be_nil
  end

  it 'has a form tag' do
    expect(rendered).to have_css('form')
  end
end
