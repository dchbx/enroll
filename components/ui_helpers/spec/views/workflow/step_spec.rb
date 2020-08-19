require "rails_helper"

describe 'workflow/step' do
  let(:model) { Survey.new }
  let(:step) do
    UIHelpers::Workflow::Step.new 'lines' => []
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
