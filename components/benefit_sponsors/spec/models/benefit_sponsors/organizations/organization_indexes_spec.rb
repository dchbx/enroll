require "rails_helper"

RSpec.describe BenefitSponsors::Organizations::Organization, "with indexes", :dbclean => :after_each do
  it "build the indexes without error" do
    described_class.remove_indexes
    described_class.create_indexes
  end
end
