require 'rails_helper'

RSpec.describe Workflow::Workflow do

  context "initializes" do
    let(:workflow3) { Workflow::Workflow.new }

    context "from hash" do
      context "is empty hash" do
        before :each do
          workflow3.workflow_step = {}
          workflow3.initialize_steps_from_hash(workflow3.workflow_step)
        end

        it "should be empty" do
          expect(workflow3.workflow_step).to be_empty
        end
      end

      context "non empty hash" do
        it "should not be empty" do
          expect(workflow3.workflow_step).not_to be_empty
          expect(workflow3.workflow_step).to have_key("step1")
          expect(workflow3.workflow_step["step1"]).not_to be_empty
        end

        it "generates the step object for step" do
          expect(workflow3.workflow_step).to have_key("step1")
          step1_step_obj = Workflow::Workflowstep.new(workflow3.workflow_step["step1"])
          expect(step1_step_obj).to be_truthy
        end

        it "puts the fields in the step" do
          expect(workflow3.workflow_step).to have_key("step1")
          expect(workflow3.workflow_step["step1"]).to have_key("title")
          expect(workflow3.workflow_step["step1"]).to have_key("description")
          expect(workflow3.workflow_step["step1"]).to have_key("question")
          expect(workflow3.workflow_step["step1"]).not_to have_key("failed_key")
        end
      end

      context "has more than one step" do
        before :each do
          @step_1 = {"step1" => {"title" => "name", "description" => "full name", "question" => "whats your name?"}}
          @step_2 = {"step2" => {"title" => "age", "description" => "full age", "question" => "whats your age?"}}
        end

        it "should generates steps in right order" do
          expect(workflow3.workflow_step["step1"]).to eq @step_1["step1"]
          expect(workflow3.workflow_step["step2"]).to eq @step_2["step2"]
        end

        it "should not generate steps in wrong order" do
          expect(workflow3.workflow_step["step1"]).not_to eq @step_2["step2"]
          expect(workflow3.workflow_step["step2"]).not_to eq @step_1["step1"]
        end
      end
    end

    context "converts yaml to hash" do
      before :each do
        @yaml_hash = YAML.load_file("config/workflow/financial_assistance.yml")
      end

      it "should convert yaml file to a hash" do
        expect(@yaml_hash.class).to eq Hash
      end
    end

    context "from yaml" do
      before :each do
        @yaml_hash = YAML.load_file("config/workflow/financial_assistance.yml")
      end

      it "should not be empty" do
        expect(@yaml_hash).not_to be_empty
      end

      it "should not raise error when yaml is valid" do
        record1 = workflow3.from_yaml("config/workflow/financial_assistance.yml")
        expect(record1).to be_present
      end

      it "should raise error when yaml is invalid" do
        record2 = workflow3.from_yaml("config/workflow/invalid.yml")
        expect(record2).not_to be_present
      end
    end

    context "with person" do
      let(:person1) {FactoryGirl.create(:person)}
      let(:workflow4) { Workflow::Workflow.new(person_id: person1.id)}

      it "should have a person_id and person" do
        expect(workflow4.person_id).not_to be nil
        expect(workflow4.person).to be_present
      end

    end
  end

  context "it loads steps" do
    it "tells you whether person has workflow for X role" do
    end
  end
end
