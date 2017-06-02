require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_qle_effective_on_kind")

describe UpdateConversionFlag do

  let(:given_task_name) { "update_qle_effective_on_kind" }
  subject { UpdateQleEffectiveOnKind.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update qle effective on kind" do
    let(:qle) { FactoryGirl.create(:qualifying_life_event_kind, :death_of_dependent )}
    
    before(:each) do
      allow(ENV).to receive(:[]).with("title").and_return(qle.title)
      allow(ENV).to receive(:[]).with("effective_on_kinds").and_return(qle.effective_on_kinds)
    end

    it "should change the effective on kind" do
      expect(qle.effective_on_kinds).to eq (["first_of_next_month"])
      subject.migrate
      qle.reload
      expect(qle.effective_on_kinds).to eq (["date_of_event"])
    end
  end
end