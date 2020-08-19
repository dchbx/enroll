require "rails_helper"

describe 'workflow/_checkbox' do
  let(:line) do
    UIHelpers::Workflow::Line.new text: 'I am a DC resident who is homeless or have no permanent home address', 'identifier' => 'resident'
  end

  before do
    render partial: 'workflow/checkbox', locals: { line: line }
  end

  it 'renders' do
    expect(rendered).to_not be_nil
  end

  it 'has dropdown list' do
    expect(rendered).to have_css('input[type=checkbox]')
  end

end






# require "rails_helper"

# describe 'workflow/_dropdown' do
#   let(:line) do
#     UIHelpers::Workflow::Line.new text: 'Are you cool?', 'values' => ['Very!', 'A Little', 'None']
#   end

#   before do
#     render partial: 'workflow/dropdown', locals: { line: line }
#   end

#   it 'renders' do
#     expect(rendered).to_not be_nil
#   end

#   it 'has dropdown list' do
#     expect(rendered).to have_css('select')
#   end

# end




