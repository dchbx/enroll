class QuoteDemographic
  include Mongoid::Document
  include Mongoid::Timestamps

  field :market, type: String, default: "Profession"
  field :average_household_size, type: Float, default: 3.3
  field :age_from, type: Integer, default: 16
  field :age_to, type: Integer, default: 65

  def generate_random_age
    rand(age_from..age_to)
  end

  def generate_random_age_children
    rand(1..21)
  end

  def provide_quote_roster
    return if average_household_size < 1

    roster = Array.new
    household_count = self.average_household_size.ceil
    count = 1

    if count == 1
      roster.push({:employee_relationship => "employee", :age => generate_random_age})
      count = count + 1
    end

    if household_count > 1 && count == 2
      roster.push({:employee_relationship => "spouse", :age => generate_random_age})
      count = count + 1
    end

    while count <= household_count do
      roster.push({:employee_relationship => "child", :age => generate_random_age_children})
      count = count + 1
    end

    roster

  end

end
