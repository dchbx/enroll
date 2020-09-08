module Parsers::Xml::Cv
  class FamilyBrokerAccountsParser
    include HappyMapper

    tag 'broker_account'

    element :broker_npn, String
    element :start_on, Date
    element :end_on, Date

    def to_hash
      {
        broker_npn: broker_npn,
        start_on: start_on,
        end_on: end_on
      }
    end
  end
end
