require "rails_helper"

module TransportProfiles
  describe ProcessContext do
    let(:process) { instance_double(Processes::Process) }

    subject { ProcessContext.new(process) }

    it "does not allow the same key to be set twice" do
      subject.put(:key1, "abcde")
      expect { subject.put(:key1, "abcde") }.to  raise_error(NameError, "name already exists in this context")
    end

    it "does not allow referencing an undefined key" do
      expect { subject.get("bogus_key") }.to raise_error(KeyError, "key not found: :bogus_key")
    end
  end

  describe ProcessContext, "#update" do
    let(:process) { instance_double(Processes::Process) }

    subject { ProcessContext.new(process) }

    it "yields the provided intial value when the value is unset" do
     subject.update(:key1, "abcde") do |arg|
       expect(arg).to eq "abcde"
     end
    end

    it "yields the pre-existing value if it exists" do
      subject.put(:key1, "original value")
      subject.update(:key1, "abcde") do |arg|
        expect(arg).to eq "original value"
      end
    end

    it "updates the value to the value of the block" do
      subject.put(:key1, 5)
      subject.update(:key1, 12) do |arg|
        arg + 10
      end
      expect(subject.get(:key1)).to eq 15
    end
  end
end
