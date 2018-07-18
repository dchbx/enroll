require 'rails_helper'

RSpec.describe "routing", :type => :routing do
  it "routes /insured/consumer_role/immigration_document_options to consumer_roles#immigration_document_options" do
    expect(:get => "/insured/consumer_role/immigration_document_options").to route_to(
      :controller => "insured/consumer_roles",
      :action => "immigration_document_options"
    )
  end  
end
