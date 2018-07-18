module Forms
  module PeopleNames
    include ::Forms::FnameLname

    def middle_name
      @middle_name
    end

    def name_pfx
      @name_pfx
    end

    def name_sfx
      @name_sfx
    end

    def middle_name=(val)
      @middle_name = val.blank? ? nil : val.strip
    end

    def name_pfx=(val)
      @name_pfx =  val.blank? ? nil : val.strip
    end

    def name_sfx=(val)
      @name_sfx =  val.blank? ? nil : val.strip
    end
  end
end
