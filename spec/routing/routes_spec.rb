require 'rails_helper'

RSpec.describe "routing", :type => :routing do
  it "routes /insured/consumer_role/immigration_document_options to consumer_roles#immigration_document_options" do
    expect(:get => "/insured/consumer_role/immigration_document_options").to route_to(
      :controller => "insured/consumer_roles",
      :action => "immigration_document_options"
    )
  end

  describe "general agency can be enabled or disabled via settings" do
    context "when enabled" do
      it "routes to general_agency_registration by default" do
        expect(get: "/general_agency_registration").to route_to(
          controller: 'general_agencies/profiles',
          action: 'new_agency'
        )
      end

      it "routes to general_agencies profiles" do
        expect(get: '/general_agencies').to route_to(
          controller: 'general_agencies/profiles',
          action: 'new'
        )
      end
    end

    pending "when disabled" do
      let(:site) { double(general_agency_enabled: false) }
      before do
        Settings.site = site
      end

      it "routes to general_agency_registration by default" do
        expect(get: "/general_agency_registration").not_to be_routable
      end

      it "routes to general_agencies profiles" do
        expect(get: '/general_agencies').not_to be_routable
      end
    end
  end
end
