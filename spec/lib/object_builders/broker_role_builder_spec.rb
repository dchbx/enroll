# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib', 'object_builders', 'broker_role_builder')

describe BrokerRoleBuilder do

  before(:all) do
    @broker_hash = {
      :npn => "1310000",
      :license_number => "1310000",
      :state => "DC",
      :name => {
        :first_name => "Pam",
        :last_name => "Sahouri",
        :full_name => "Pam M. Sahouri"
      },
      :phones => [
          {
            :kind => "work",
            :full_phone_number => "+1-703-000-0500"
          }
        ],
      :emails => [
          {:kind => "work", :address => "benefits@sample.com"}
        ],
      :addresses => [
          {:kind => "Work", :street => "8200 Sample NE", :locality => "Mclean", :region => "MD", :code => "22100", :country => "USA"}
        ],
      :exchange_id => nil, :exchange_status => "ACTIVE"
    }
    @broker_builder = BrokerRoleBuilder.new(@broker_hash)
    @broker_builder.build
  end

  it 'sets the name fields' do
    expect(@broker_builder.person.first_name).to eq(@broker_hash[:name][:first_name])
    expect(@broker_builder.person.last_name).to eq(@broker_hash[:name][:last_name])
  end

  it 'sets the broker fields' do
    expect(@broker_builder.broker.npn).to eq(@broker_hash[:npn])
  end

  it 'creates a valid Person object' do
    expect(@broker_builder.person.valid?).to be_truthy
  end

  it 'creates a valid BrokerRole object' do
    expect(@broker_builder.person.broker_role.valid?).to be_truthy
  end

  it 'saves the Person object' do
    expect(@broker_builder.save).to be_truthy
  end
end
