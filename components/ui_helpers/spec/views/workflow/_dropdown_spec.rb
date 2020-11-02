# frozen_string_literal: true

require "rails_helper"

describe 'workflow/_dropdown' do
  let(:line) do
    UIHelpers::Workflow::Line.new "cells" => [{"name" => "test", "attribute" => "is_required_to_file_taxes", "text" => 'Are you cool?', 'values' => ['Very!', 'A Little', 'None']}]
  end

  let(:model) {double(FinancialAssistance::Applicant, is_required_to_file_taxes: nil)}

  before do
    assign(:model, model)
    render partial: 'workflow/dropdown', locals: { cell: line.cells[0] }
  end

  it 'renders' do
    expect(rendered).to_not be_nil
  end

  it 'has dropdown list' do
    expect(rendered).to have_css('select')
  end

end







