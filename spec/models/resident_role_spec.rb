require 'rails_helper'
require 'aasm/rspec'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe ResidentRole, :type => :model do
  it { should delegate_method(:hbx_id).to :person }
  it { should delegate_method(:ssn).to :person }
  it { should delegate_method(:dob).to :person }
  it { should delegate_method(:gender).to :person }
  it { should delegate_method(:is_incarcerated).to :person }
  it { should validate_presence_of :gender }
  it { should validate_presence_of :dob }
end
end
