require 'rails_helper'

describe "shared/inboxes/_message_list.html.erb" do
  let(:shared_message_properties) do
    {
        :from => "somebody",
        :folder => "Inbox",
        :message_read => false
    }
  end

  let(:message_1) { instance_double(Message, {:id => "11111", :created_at=>DateTime.new(2016,1,1)}.merge(shared_message_properties)) }
  let(:message_2) { instance_double(Message, {:id => "22222", :created_at=>DateTime.new(2016,11,11)}.merge(shared_message_properties)) }
  let(:mock_inbox) { instance_double(Inbox, {:messages => [message_1, message_2], :unread_messages => [message_1, message_2]}) }
  let(:mock_provider) { instance_double(EmployerProfile,{:id => "12345", :model_name => EmployerProfile, :inbox => mock_inbox} ) }
  before :each do
    assign(:folder,"Sent")
    assign(:sent_box, true)
    assign(:provider,mock_provider)
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
    render "insured/families/inbox.html.erb"
  end

  it "should have text From" do
    expect(rendered).to have_content("From")
  end
  it "should not have text FROM" do
    expect(rendered).to_not have_content("FROM")
  end
  it "should not have text Inbox: FROM" do
    expect(rendered).to_not have_content("Inbox: FROM")
  end

end
