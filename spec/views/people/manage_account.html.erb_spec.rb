# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "people/manage_account.html.erb", :type => :view, dbclean: :after_each do

  let!(:user) { FactoryBot.create(:user) }
  let!(:person) { FactoryBot.create(:person, user: user) }

  before do
    sign_in(user)
    assign(:person, person)
    render template: 'people/manage_account.html.erb'
  end


  it 'should render lmy account text' do
    expect(rendered).to match(/My Account/)
    expect(rendered).to match(/The Manage Account “home” page is a page to explain the access the user has for all features which are currently accessible./)
  end
end
