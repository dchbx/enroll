class EngineTest
  include SimpleRulesEngine
  rule :equal_one,
         priority: 10,
         validate: lambda {|v,fact| v == 1 },
         success: lambda {|v,fact| puts "wohoo " + fact.object.first_name },
         fail: lambda {|v,fact| puts "fail"}

   rule :greater_equal_to_one,
          priority: 10,
          validate: lambda {|v,fact| v >= 1 },
          success: lambda {|v,fact| puts "wohoo" },
          fail: lambda {|v,fact| puts "fail"}


  attr_accessor :object
  attr_accessor :policy

  def initialize(object,policy=nil)
    @object = object
    @policy = policy
  end

end
