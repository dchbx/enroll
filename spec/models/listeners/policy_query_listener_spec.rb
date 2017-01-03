require 'rails_helper'

describe ::Listeners::PolicyQueryListener do
  let(:reply_exchange) { double }
  let(:reply_channel) { double(:close => true, :confirm_select => true, :default_exchange => reply_exchange, :wait_for_confirms => true) }
  let(:connection) { double(:create_channel => reply_channel) }
  let(:channel) { double(:connection => connection) }
  let(:reply_exchange) { double }
  let(:queue) { double }
  let(:reply_to) { "reply to key" }
  let(:properties) { double(:headers => headers, :reply_to => reply_to) }
  let(:delivery_tag) { double }
  let(:delivery_info) { double(:delivery_tag => delivery_tag) }
  let(:body) { "" }

  subject { ::Listeners::PolicyQueryListener.new(channel, queue) }

  describe "given an invalid query name" do
    let(:headers) do
      { "query_criteria_name" => "some bogus name D00000D" }
    end

    before :each do
      allow(reply_exchange).to receive(:publish).with("Invalid query name specified.", {reply_to: reply_to, headers: {return_status: "422"}})
      allow(channel).to receive(:acknowledge).with(delivery_tag, false)
    end

    it "replies with a 422 explaining the query_criteria_name is invalid" do
      expect(reply_exchange).to receive(:publish).with("Invalid query name specified.", {reply_to: reply_to, headers: {return_status: "422"}})
      subject.on_message(delivery_info, properties, body)
    end

    it "should acknowledge the message" do
      expect(channel).to receive(:acknowledge).with(delivery_tag, false)
      subject.on_message(delivery_info, properties, body)
    end
  end

  describe "given a valid query name, and an exclusion list" do
    let(:headers) do
      { "query_criteria_name" => "all_outstanding_shop" }
    end

    let(:new_policy_id) { "new policy id" }
    let(:excluded_policy_id) { "excluded policy id" }

    let(:exclusion_list) { [excluded_policy_id] }
    let(:json_exclusion_list) { JSON.dump(exclusion_list) }

    let(:policy_id_list) { [excluded_policy_id, new_policy_id] }

    before :each do
      allow(::Queries::NamedPolicyQueries).to receive(:all_outstanding_shop).and_return(policy_id_list)
      allow(PayloadInflater).to receive(:inflate).with(false, body).and_return(json_exclusion_list)
      allow(channel).to receive(:acknowledge).with(delivery_tag, false)
      allow(reply_exchange).to receive(:publish).with(JSON.dump([new_policy_id]), {routing_key: reply_to, headers: {return_status: "200"}})
    end

    it "replies with a 200 and the list of policies" do
      expect(reply_exchange).to receive(:publish).with(JSON.dump([new_policy_id]), {routing_key: reply_to, headers: {return_status: "200"}})
      subject.on_message(delivery_info, properties, body)
    end

    it "consumes the message" do
      expect(channel).to receive(:acknowledge).with(delivery_tag, false)
      subject.on_message(delivery_info, properties, body)
    end
  end
end
