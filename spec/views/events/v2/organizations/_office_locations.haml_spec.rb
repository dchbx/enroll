require 'rails_helper'

RSpec.describe "app/views/events/v2/organizations/_office_location.xml.haml" do

  describe "office location xml" do
    let(:office_location) { FactoryGirl.build(:office_location, is_primary:true) }

    context "phone" do
      context "kind = work" do
        before :each do
          office_location.phone.kind="work"
          render :template => "events/v2/organizations/_office_location.xml.haml", :locals => {:office_location => office_location}
          @doc = Nokogiri::XML(rendered)
        end

        it "should have type as work" do
          expect(@doc.xpath("//phone/type").first.text).to eq "urn:openhbx:terms:v1:phone_type#work"
        end
      end

      context "kind = mobile" do
        before :each do
          office_location.phone.kind="mobile"
          render :template => "events/v2/organizations/_office_location.xml.haml", :locals => {:office_location => office_location}
          @doc = Nokogiri::XML(rendered)
        end

        it "should not have the phone tag" do
          expect(@doc.xpath("//phone").count).to eq 0
        end
      end
    end

    context "address" do
      context "kind == work" do
        before :each do
          office_location.address.kind="work"
          render :template => "events/v2/organizations/_office_location.xml.haml", :locals => {:office_location => office_location}
          @doc = Nokogiri::XML(rendered)
        end

        it "should have address with type 'work'" do
          expect(@doc.xpath("//address/type").first.text).to eq "urn:openhbx:terms:v1:address_type#work"
        end
      end

      context "kind == branch" do
        before :each do
          office_location.address.kind="branch"
          render :template => "events/v2/organizations/_office_location.xml.haml", :locals => {:office_location => office_location}
          @doc = Nokogiri::XML(rendered)
        end

        it "should not have the address tag" do
          expect(@doc.xpath("//address").count).to eq 0
        end
      end
    end
  end
end