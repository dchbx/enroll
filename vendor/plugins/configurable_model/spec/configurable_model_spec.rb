require 'spec_helper'

describe ConfigurableModel do
  it 'has a version number' do
    expect(ConfigurableModel::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
