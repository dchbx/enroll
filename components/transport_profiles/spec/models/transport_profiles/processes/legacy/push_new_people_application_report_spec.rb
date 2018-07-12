require "rails_helper"

module TransportProfiles
  describe Processes::Legacy::PushNewPeopleApplicationReport, "provided a file and a gateway" do
    let(:report_file_name) { double }
    let(:gateway) { double }

    subject { Processes::Legacy::PushNewPeopleApplicationReport.new(report_file_name, gateway) }

    it "has 3 steps" do
      expect(subject.steps.length).to eq 3
    end

    it "has 3 step_descriptions" do
      expect(subject.step_descriptions.length).to eq 3
    end
  end
end
