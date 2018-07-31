module Forms
  module FnameLname
    def first_name
      @first_name
    end

    def last_name
      @last_name
    end

    def first_name=(val)
      @first_name = val.blank? ? nil : val.strip
    end

    def last_name=(val)
      @last_name = val.blank? ? nil : val.strip
    end
  end
end
