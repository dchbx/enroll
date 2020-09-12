# frozen_string_literal: true

require "rails_helper"

describe 'workflow/_radio' do
  let(:line) do
    UIHelpers::Workflow::Line.new "cells" => [{'text' => 'Yo?', 'values' => ['Yo!', 'No!']}]
  end

  before do
    render partial: 'workflow/radio', locals: { cell: line.cells[0] }
  end

  it 'renders' do
    expect(rendered).to_not be_nil
  end

  it 'has radio buttons' do
    expect(rendered).to have_css('input[type=radio]')
  end

  context 'with no Not Sure? help' do
    let(:line) do
      UIHelpers::Workflow::Line.new "cells" => [{'text' => 'Yo?',
                                                 'values' => ['Yo!', 'No!'],
                                                 'options' => { 'not_sure' => true, 'help_link' => '/help_me' }}]
    end

    it 'does not have a Not Sure help link' do
      expect(rendered).not_to have_xpath("//a[@href='/help_me'][contains(text(), 'Not Sure?')]")
    end
  end
end
