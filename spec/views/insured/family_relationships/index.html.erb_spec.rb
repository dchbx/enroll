# frozen_string_literal: true

require 'rails_helper'

describe "insured/family_relationships/index.html.erb" do
  let(:person) { FactoryBot.create(:person) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family) { Family.new }
  let(:test_family){FactoryBot.create(:family, :with_primary)}

  before :each do
    sign_in user
    assign :person, person
    assign :family, family
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
  end

  it "should have title" do
    render template: "insured/family_relationships/index.html.erb"
    expect(rendered).to have_selector("h1", text: 'Household Relationships')
  end

  it "should render the form partial" do
    expect(render).to render_template(partial: '_form')
  end

  it "should render the individual progress" do
    expect(render).to render_template(partial: '_individual_progress')
  end
end
