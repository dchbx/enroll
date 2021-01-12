# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "people/personal_info.html.erb", :type => :view, dbclean: :after_each do

  let!(:user) { FactoryBot.create(:user) }
  let!(:person) { FactoryBot.create(:person, user: user) }

  before do
    sign_in(user)
    assign(:person, person)
    render template: 'people/personal_info.html.erb'
  end


  it 'should render title' do
    expect(rendered).to have_selector('h1', text: 'Personal Information')
  end

  it "should render personal information labels" do
    expect(rendered).to have_selector('label', text: 'First Name')
    expect(rendered).to have_selector('label', text: 'Last Name')
  end

  it 'should display gender options dropdown' do
    expect(rendered).to have_select("person_gender", :options => ['Male', 'Female'])
  end

  it 'should display contact type options dropdown' do
    expect(rendered).to have_select("person_emails_attributes_0_kind", :options => ['SELECT KIND', 'work', 'home'])
  end

  it 'should display save changes button' do
    expect(rendered).to have_button('Save Changes')
  end

  it 'should display cancel changes link' do
    expect(rendered).to have_link('Cancel')
  end
end
