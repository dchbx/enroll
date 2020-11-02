# frozen_string_literal: true

module Parsers
  module Xml
    module Cv
      module Haven
        class IndividualPersonParser
          include HappyMapper
          register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
          namespace 'n1'

          tag 'person'
          element :id, String, tag: 'id/n1:id'

        end
      end
    end
  end
end
