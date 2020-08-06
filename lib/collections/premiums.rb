# frozen_string_literal: true

module Collections
  class Premiums
    def initialize(premiums)
      @premiums = premiums
    end

    def for_age(age)
      results = @premiums.select { |p| p.age == age}
      Collections::Premiums.new(results)
    end

    def for_date(date)
      results = @premiums.select { |p| ((p.start_on)..(p.end_on)).cover?(date) }
      Collections::Premiums.new(results)
    end

    def to_a
      @premiums
    end
  end
end
