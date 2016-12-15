require "rails_helper"

describe Events::PoliciesController do
  describe "providing a resource" do
    let(:policy) { double }
    let(:policy_id) { "the hbx id for this policy" }
    let(:rendered_template) { double }
    let(:di) { double }
    let(:channel) { double(:default_exchange => exchange, :close => nil) }
    let(:reply_to_key) { "some queue name" }
    let(:exchange) { double }
    let(:connection) { double(:create_channel => channel) }
    let(:props) { double(:headers => {:policy_id => policy_id}, :reply_to => reply_to_key) }

    before :each do
      allow(HbxEnrollment).to receive(:by_hbx_id).with(policy_id).and_return(found_policys)
      allow(controller).to receive(:render_to_string).with(
        "events/enrollment_event", {:formats => ["xml"], :locals => {
         :hbx_enrollment => policy
        }}).and_return(rendered_template)
    end

    describe "for an existing policy" do
      let(:found_policys) { [policy] }
      let(:eligibility_event_kind) { "some event like open enrollment maybe?" }

      before :each do
        allow(policy).to receive(:eligibility_event_kind).and_return(eligibility_event_kind)
      end

      it "should send out a message to the bus with the rendered policy object" do
        expect(exchange).to receive(:publish).with(rendered_template, {
          :routing_key => reply_to_key,
          :headers => {
            :policy_id => policy_id,
            :return_status => "200",
            :eligibility_event_kind => eligibility_event_kind
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end

    describe "for a policy which cannot be properly rendered" do
      let(:found_policys) { [policy] }
      let(:exception) { Exception.new("Some exception") }
      let(:exception_backtrace) { ["some error message on a line"] }

      before :each do
        allow(controller).to receive(:render_to_string).with(
          "events/enrollment_event", {:formats => ["xml"], :locals => {
            :hbx_enrollment => policy
          }}).and_raise(exception)
        allow(exception).to receive(:backtrace).and_return(exception_backtrace)
      end

      it "should send out a message to the bus with the error code and exception" do
        expect(exchange).to receive(:publish).with(JSON.dump({
           exception: exception.inspect,
           backtrace: exception_backtrace.inspect 
          }), {
          :routing_key => reply_to_key,
          :headers => {
            :policy_id => policy_id,
            :return_status => "500"
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end

    describe "for a policy which doesn't exist" do
      let(:found_policys) { [] }

      it "should send out a message to the bus with no policy object" do
        expect(exchange).to receive(:publish).with("", {
          :routing_key => reply_to_key,
          :headers => {
            :policy_id => policy_id,
            :return_status => "404"
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end
  end

end
