require 'rails_helper'

RSpec.describe Inbox, :type => :model do
  let (:inbox) {Inbox.new}
  let (:message) {FactoryGirl.build(:message)}
  let (:message_list) {FactoryGirl.build_list(:message, 15)}

  describe "#post_message" do

    context "with valid message" do
      let(:inbox_with_message) { inbox.post_message(message) }

      it "should add to collection" do
        expect(inbox_with_message.messages.size).to eq 1
      end
    end
  end

  describe "#read_messages" do
    let(:read_messages) {FactoryGirl.build_list(:message, 3, message_read: true, folder: "inbox")}
    let(:unread_messages) {FactoryGirl.build_list(:message, 4, message_read: false, folder: "inbox")}
    let(:messages) {[read_messages + unread_messages]}

    before do
      inbox.messages << messages
    end

    context "read_messages" do
      it "should return correct count of read messages" do
        expect(inbox.read_messages.count).to eq read_messages.count
      end
    end

    context "#unread_messages" do
      it "should return correct count of unread messages" do
        expect(inbox.unread_messages.count).to eq unread_messages.count
      end
    end
  end

  describe "#delete_message" do
    let(:orphan_message) {FactoryGirl.build(:message)}
    let(:message_count) {15}

    let(:inbox_with_many_messages) do
      inbox = Inbox.new
      message_count.times do
        message = FactoryGirl.build(:message)
        inbox.post_message(message)
      end
      inbox
    end

    context "messages are loaded" do
      it "inbox should contain list of messages" do
        expect(inbox_with_many_messages.messages.size).to eq message_count
      end
    end

    context "and message to delete is not in mailbox" do
      it "should not change message count" do
        expect(inbox_with_many_messages.delete_message(orphan_message).messages.size).to eq message_count
      end
    end

    context "and message to delete is in mailbox" do
      let(:deleteable_message) { inbox_with_many_messages.messages.first }
      it "should reduce message count by 1" do
        expect(inbox_with_many_messages.delete_message(deleteable_message).messages.size).to eq message_count - 1
      end
    end
  end
end
