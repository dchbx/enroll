require 'rails_helper'

describe Workflow::Workflowstep do

  context "initializes" do
    let(:workflow3) { Workflow::Workflow.new }
    context "from hash" do

      context "creates one instance of a step object" do
        it "should create one instance for each step" do
          step1_record = Workflow::Workflowstep.new(workflow3.workflow_step["step1"])
          expect(step1_record).to be_truthy
          step2_record = Workflow::Workflowstep.new(workflow3.workflow_step["step2"])
          expect(step2_record).to be_truthy
        end
      end

      context "saves the values to the fields correctly" do
        it "should save the fields correctly" do
          step1_record = Workflow::Workflowstep.new(workflow3.workflow_step["step1"])
          expect(step1_record.title).to eq "name"
          expect(step1_record.description).to eq "full name"
          expect(step1_record.question).to eq "whats your name?"
        end
      end
    end
  end
end
