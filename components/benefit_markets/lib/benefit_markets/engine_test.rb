class EngineTest
  include SimpleRulesEngine
  rule :name_of_rule,
         priority: 10,
         validate: lambda {|o| puts "hello" },
         fail: lambda {|o| puts "fail"}

end
