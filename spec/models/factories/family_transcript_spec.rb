require 'rails_helper'

RSpec.describe Factories::FamilyTranscript, type: :model do

  describe "find_or_build_family" do
    context "Family is new" do

      context "and the family_transcript is nil" do
        it "should return an prototype family_transcript" do
          # expect { Factories::FamilyTranscript.find_or_build_family(nil) }.to raise_error(Factories::FamilyTranscriptError)
        end
      end

    end

    context "Family already exists" do

    end
  end


end
