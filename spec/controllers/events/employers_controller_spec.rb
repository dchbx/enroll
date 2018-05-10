require "rails_helper"

describe Events::EmployersController do
  describe "#resource with an employer_id" do
    let(:employer_hbx_id) { "the hbx id for this employer" }
    let(:employer_org) { double(:employer_profile => employer_profile) }
    let(:employer_profile) { double }
    let(:rendered_template) { double }
    let(:di) { double }
    let(:channel) { double(:default_exchange => exchange, :close => nil) }
    let(:reply_to_key) { "some queue name" }
    let(:exchange) { double }
    let(:connection) { double(:create_channel => channel) }
    let(:props) { double(:headers => {:employer_id => employer_hbx_id}, :reply_to => reply_to_key) }

    before :each do
      allow(Organization).to receive(:employer_by_hbx_id).with(employer_hbx_id).and_return(found_orgs)
      allow(controller).to receive(:render_to_string).with(
        "events/v2/employers/updated", {:formats => ["xml"], :locals => {
         :employer => employer_profile, manual_gen: false
        }}).and_return(rendered_template)
    end

    describe "for an existing employer" do
      let(:found_orgs) { [employer_org] }

      it "should send out a message to the bus with the rendered employer object" do
        expect(exchange).to receive(:publish).with(rendered_template, {
          :routing_key => reply_to_key,
          :headers => {
            :employer_id => employer_hbx_id,
            :return_status => "200"
          }
        })
        controller.resource(connection, di, props, "")
      end
    end

    describe "for an employer which doesn't exist" do
      let(:found_orgs) { [] }

      it "should send out a message to the bus with no employer object" do
        expect(exchange).to receive(:publish).with("", {
          :routing_key => reply_to_key,
          :headers => {
            :employer_id => employer_hbx_id,
            :return_status => "404"
          }
        })
        controller.resource(connection, di, props, "")
      end
    end
  end
end
