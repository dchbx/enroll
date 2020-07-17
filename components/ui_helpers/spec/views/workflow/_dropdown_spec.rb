require "rails_helper"

describe 'workflow/_dropdown' do
  let(:line) do
    UIHelpers::Workflow::Line.new text: 'Are you cool?', 'values' => ['Very!', 'A Little', 'None']
  end

  before do
    render partial: 'workflow/dropdown', locals: { line: line }
  end

  it 'renders' do
    expect(rendered).to_not be_nil
  end

  it 'has dropdown list' do
    expect(rendered).to have_css('select')
  end

end







