require "rails_helper"

RSpec.describe L10nHelper, :type => :helper do
  # All translations are configured to load before every rspec
  it "should translate existing translations" do
    expect(helper.l10n('date')).to eq("Date")
  end

  it "should handle non existent translations gracefully" do
    expect(helper.l10n('pizza')).to eq("Pizza")
  end

  it "should handle non string translation keys gracefully" do
    expect(helper.l10n({:formats=>{:default=>"%m/%d/%Y"}})).to eq('Translation Missing')

  end
end
