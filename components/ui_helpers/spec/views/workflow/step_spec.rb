require 'rails_helper'

describe 'workflow/step' do
  let(:model) {double(FinancialAssistance::Application, is_required_to_file_taxes: nil, id: '100')}
  let(:steps) { double(last_step?: false) }
  let(:test_model) do
    { 'heading' => 'Heading',
      'heading_text' => 'Heading Text',
      'sections' => [{'section' => {'lines' => [{"cells" => [{"text" => 'I am a DC resident who is homeless or have no permanent home address', 'identifier' => 'resident'}]}],
                                    'heading' => 'Heading'}}]}
  end
  let(:step) do
    allow(model).to receive(:find).with('100').and_return(model)
    allow(model).to receive(:new_record?).and_return(true)
    UIHelpers::Workflow::Step.new test_model, 3, []
  end

  before do
    stub_template "./ui-components/v1/modals/_help_with_plan.html.slim" => ''
    assign :current_step, step
    assign :model, model
    assign :application, model
    assign :steps, steps
    render
  end

  it 'renders' do
    expect(rendered).to_not be_nil
  end

  it 'has a form tag' do
    expect(rendered).to have_css('form')
  end
end
