# frozen_string_literal: true

class EngineTest
  include SimpleRulesEngine
  rule :equal_one,
       priority: 10,
       validate: ->(v, _fact) { v == 1 },
       success: ->(_v, fact) { puts "wohoo #{fact.object.first_name}" },
       fail: ->(_v, _fact) { puts "fail"}

  rule :greater_equal_to_one,
       priority: 10,
       validate: ->(v, _fact) { v >= 1 },
       success: ->(_v, _fact) { puts "wohoo" },
       fail: ->(_v, _fact) { puts "fail"}


  attr_accessor :object, :policy

  def initialize(object,policy = nil)
    @object = object
    @policy = policy
  end

end
