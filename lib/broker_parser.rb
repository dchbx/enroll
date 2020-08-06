# frozen_string_literal: true

class Type
  include HappyMapper
  tag 'type'
  namespace 'ns1'
  element :text, String, :tag => "text"
end

class Parameter
  include HappyMapper
  tag 'parameters'
  namespace 'ns1'
  has_one :type, Type
end


class BrokerAddress
  include HappyMapper
  tag 'adr'
  namespace 'ns1'
  has_one :parameter, Parameter
  element :street, String
  element :locality, String
  element :region, String
  element :code, String
  element :country, String
end

class BrokerPhone
  include HappyMapper
  tag 'tel'
  namespace 'ns1'
  has_one :parameter, Parameter
  element :uri, String
end

class BrokerEmail
  include HappyMapper
  tag 'email'
  namespace 'ns1'
  has_one :parameter, Parameter
  element :text, String
end

class BrokerPerson
  include HappyMapper
  tag 'n'
  namespace 'ns1'
  element :surname, String
  element :given, String

end

class Vcard
  include HappyMapper
  tag 'vcard'
  namespace 'ns1'
  element :org, String, :tag => "org"
  has_one :broker_address, BrokerAddress
  has_one :broker_phone, BrokerPhone
  has_one :broker_email, BrokerEmail
  has_one :person, BrokerPerson
end

class BrokerParser
  include HappyMapper
  tag 'broker'
  namespace 'ns1'
  element :npn, String, :tag => "npn"
  has_one :vcard, Vcard

  # has_one :broker_address, BrokerAddress, :tag => 'adr'
  # has_one :broker_phone, BrokerPhone, :tag => 'tel'
  # has_one :broker_email, BrokerEmail, :tag => 'email'
end