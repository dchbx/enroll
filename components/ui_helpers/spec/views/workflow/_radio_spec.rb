require "rails_helper"

describe 'workflow/_radio' do
  let(:line) do
    UIHelpers::Workflow::Line.new 'text' => 'Yo?', 'values' => ['Yo!', 'No!']
  end

  before do
    render partial: 'workflow/radio', locals: { line: line }
  end

  it 'renders' do
    expect(rendered).to_not be_nil
  end

  it 'has radio buttons' do
  	expect(rendered).to have_css('input[type=radio]')
  end

  context 'with Not Sure? help' do
  	let(:line) do
  		UIHelpers::Workflow::Line.new 'text' => 'Yo?',
       'values' => ['Yo!', 'No!'],
        'options' => { 'not_sure' => true, 'help_link' => '/help_me' }
  	end

    it 'has a Not Sure help link' do
      expect(rendered).to have_xpath("//a[@href='/help_me'][contains(text(), 'Not Sure?')]")
    end
  end
end
