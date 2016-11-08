require 'rails_helper'

RSpec.describe "app/views/events/v2/addresses/_address.xml.haml" do


  describe "an address" do
    let(:address) { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }

    context "kind=`primary`" do
      before :each do
        render :template => "events/v2/addresses/_address.xml.haml", :locals => {:address => address}
        @doc = Nokogiri::XML(rendered)
      end

      it "should have type as `work`" do
        expect(@doc.xpath("//address/type").first.text).to eq "urn:openhbx:terms:v1:address_type#work"
      end
    end
  end
end
