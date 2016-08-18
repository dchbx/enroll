require 'rails_helper'

RSpec.describe "events/v2/organizations/_office_location.xml.haml" do

  describe "office location xml" do
    let(:office_location) { FactoryGirl.build(:office_location) }

    context "address type 'branch'" do
      before :each do
        render :template => "events/v2/organizations/_office_location.xml.haml", :locals => {:office_location => office_location}
        @doc = Nokogiri::XML(rendered)
      end

      it "does not include 'branch' address" do
        expect(@doc.xpath("//address[type='urn:openhbx:terms:v1:address_type#branch']").count).to eq(0)
      end
    end

    context "address type 'mailing'" do
      before :each do
        office_location.address.kind = 'mailing'
        render :template => "events/v2/organizations/_office_location.xml.haml", :locals => {:office_location => office_location}
        @doc = Nokogiri::XML(rendered)
      end

      it "does include `mailing` address" do
        expect(@doc.xpath("//address[type='urn:openhbx:terms:v1:address_type#mailing']").count).to eq(1)
        address = @doc.xpath("//address").first

        expect(address.xpath('//location_city_name').text).to eq office_location.address.city
        expect(address.xpath('//postal_code').text).to eq office_location.address.zip
        expect(address.xpath('//location_state').text).to eq "urn:openhbx:terms:v1:us_state#district_of_columbia"


      end
    end

    context "phone type 'work'" do
      before :each do
        render :template => "events/v2/organizations/_office_location.xml.haml", :locals => {:office_location => office_location}
        @doc = Nokogiri::XML(rendered)
      end

      it "does include 'work' phone" do
        expect(@doc.xpath("//phone[type='urn:openhbx:terms:v1:phone_type#work']").count).to eq(1)
        phone = @doc.xpath("//phone").first

        expect(phone.xpath('//area_code').text).to eq office_location.phone.area_code
        expect(phone.xpath('//phone_number').text).to eq office_location.phone.number
      end
    end
  end
end