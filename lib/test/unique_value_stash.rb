module UniqueValueStash
  class UniqueValues
    def initialize
      @unique_values = {}
    end
    def number digits=9, key=nil
      random_value = key != :ssn ? (0.1 + 0.9*rand)* (10**digits) : (0.1 + 0.1*rand(0.8))* (10**digits)
      digit_string = random_value.to_i.to_s
      @unique_values[key] = digit_string if key
      digit_string
    end
    def find key
      @unique_values[key]
    end
    def adult_dob key=nil
      unique_date = "0#{number 1}/0#{number 1}/#{1950+rand(40)}"
      @unique_values[key] = unique_date if key
      unique_date
    end
    def last_name key=nil
      unique_last_name = "Last#{rand(100000)}"
      @unique_values[key] = unique_last_name if key
      unique_last_name
    end
    def first_name key=nil
      unique_first_name = "First#{rand(100000)}"
      @unique_values[key] = unique_first_name if key
      unique_first_name
    end
    def email key=nil
      unique_email = "email#{rand(100000)}@email.com"
      @unique_values[key] = unique_email if key
      unique_email
    end
    def ssn key=nil
      number 9, key
    end
    def fein key=nil
      number 9, key
    end
  end
end
