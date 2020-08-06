# frozen_string_literal: true

class BrokerRoleBuilder

  attr_reader :person

  def initialize(broker_hash)
    @broker_hash = broker_hash
  end

  def build
    @person = Person.create({first_name: @broker_hash[:name][:first_name], last_name: @broker_hash[:name][:last_name]})

    @broker_hash[:phones].each do |phone|
      @person.phones.build(phone)
    end
    @broker_hash[:emails].each do |email|
      @person.emails.build(email)
    end

    @broker_hash[:addresses].each do |address|
      @person.addresses.build({kind: address[:kind],
                               address_1: address[:street],
                               city: address[:locality],
                               state: address[:region],
                               zip: address[:code],
                               county: address[:county]})
    end

    @person.broker_role = BrokerRole.new({npn: @broker_hash[:npn], provider_kind: 'broker'})
  rescue Exception => e
    @person&.delete
    raise e
  end

  def save
    if @person.save
      true
    else
      @person.delete
      false
    end
  end

  def save!
    @person.save!
  rescue Exception => e
    @person.delete
    raise e
  end

  def broker
    @person.broker_role
  end
end