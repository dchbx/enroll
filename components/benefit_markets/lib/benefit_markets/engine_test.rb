# frozen_string_literal: true

class EngineTest
  include SimpleRulesEngine
  rule :name_of_rule,
       priority: 10,
       validate: ->(_o) { puts "hello" },
       fail: ->(_o) { puts "fail"}

end
