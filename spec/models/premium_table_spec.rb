require "rails_helper"

describe PremiumTable, "given a rating area value" do
  Settings.aca.rating_areas.each do |mra|
    it "is valid for a rating_area of #{mra}" do
      subject.rating_area = mra
      subject.valid?
      expect(subject.errors.keys).not_to include(:rating_area)
    end
  end

  it "is invalid for a made up rating_area" do
    subject.rating_area = "LDJFKLDJKLEFJLKDJSFKLDF"
    subject.valid?
    expect(subject.errors.keys).to include(:rating_area)
  end
end
