require 'rails_helper'

describe "shared/read_only_modal.html.erb with all options" do

  before :each do
    render :partial => "shared/modals/read_only_modal.html.erb", locals: { modal_id: 'test_id', header_icon: "<i class='fa fa-life-ring' aria-hidden='true'></i>", title: "test modal header text", body: "test modal body text" }
  end

  it "should display the modal title" do
    expect(rendered).to have_selector("h3", text: "test modal header text")
    expect(rendered).to have_selector(".fa", text: "")
    expect(rendered).to have_selector("p", text: "test modal body text")
  end
  
end
