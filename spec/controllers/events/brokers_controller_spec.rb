require "rails_helper"

describe Events::BrokersController do
  describe "providing a resource" do
    let(:broker) { double }
    let(:broker_id) { "the hbx id for this broker" }
    let(:rendered_template) { double }
    let(:di) { double }
    let(:channel) { double(:default_exchange => exchange, :close => nil) }
    let(:reply_to_key) { "some queue name" }
    let(:exchange) { double }
    let(:connection) { double(:create_channel => channel) }
    let(:props) { double(:headers => {:broker_id => broker_id}, :reply_to => reply_to_key) }

    before :each do
      allow(Person).to receive(:by_broker_role_npn).with(broker_id).and_return(found_brokers)
      allow(controller).to receive(:render_to_string).with(
        "events/brokers/created", {:formats => ["xml"], :locals => {
         :individual => broker
        }}).and_return(rendered_template)
    end

    describe "for an existing broker" do
      let(:found_brokers) { [broker] }

      it "should send out a message to the bus with the rendered broker object" do
        expect(exchange).to receive(:publish).with(rendered_template, {
          :routing_key => reply_to_key,
          :headers => {
            :broker_id => broker_id,
            :return_status => "200"
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end

    describe "for a broker which doesn't exist" do
      let(:found_brokers) { [] }

      it "should send out a message to the bus with no broker object" do
        expect(exchange).to receive(:publish).with("", {
          :routing_key => reply_to_key,
          :headers => {
            :broker_id => broker_id,
            :return_status => "404"
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end
  end

end
