module Parsers::Xml::Cv
  class EmployerRequestHeaderParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'
    tag 'header'

    def to_hash

    end

  end
end

