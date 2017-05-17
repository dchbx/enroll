require "rails_helper"

describe Events::IndividualsController do
  describe "#created with an individual created event" do
    let(:individual) { double }
    let(:individual_id) { "the hbx id for this individual" }
    let(:rendered_template) { double }
    let(:di) { double }
    let(:channel) { double(:default_exchange => exchange, :close => nil) }
    let(:reply_to_key) { "some queue name" }
    let(:exchange) { double }
    let(:connection) { double(:create_channel => channel) }
    let(:props) { double(:headers => {:individual_id => individual_id}, :reply_to => reply_to_key) }

    before :each do
      allow(Person).to receive(:by_hbx_id).with(individual_id).and_return(found_individuals)
      allow(controller).to receive(:render_to_string).with(
        "created", {:formats => ["xml"], :locals => {
         :individual => individual
        }}).and_return(rendered_template)
    end

    describe "for an existing individual" do
      let(:found_individuals) { [individual] }

      it "should send out a message to the bus with the rendered individual object" do
        expect(exchange).to receive(:publish).with(rendered_template, {
          :routing_key => reply_to_key,
          :headers => {
            :individual_id => individual_id,
            :return_status => "200"
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end

    describe "for an individual which doesn't exist" do
      let(:found_individuals) { [] }

      it "should send out a message to the bus with no individual object" do
        expect(exchange).to receive(:publish).with("", {
          :routing_key => reply_to_key,
          :headers => {
            :individual_id => individual_id,
            :return_status => "404"
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end

    describe "for when an exception is thrown" do 
      let(:found_individuals) { [individual] }
      let(:exception) { Exception.new("error thrown")}
      let(:exception_backtrace) { ["error backtrace"] }

      before :each do
        allow(Person).to receive(:by_hbx_id).with(individual_id).and_return(found_individuals)
        allow(controller).to receive(:render_to_string).and_raise(exception)

        allow(exception).to receive(:backtrace).and_return(exception_backtrace)
      end

      it "should return a 500 response and the error message" do
        expect(exchange).to receive(:publish).with(JSON.dump({
          exception: exception.inspect,
          backtrace: exception_backtrace.inspect
          }),
        {
          :routing_key => reply_to_key,
          :headers => {
            :return_status => "500",
            :individual_id => individual_id
          }
        })

        controller.resource(connection, di, props, "")
      end
    end
  end

end
