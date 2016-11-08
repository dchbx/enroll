FactoryGirl.define do
  factory :message do
    subject "phoenix project"
    body    "welcome to the hbx"
  end

  factory :message1, :class=>:Message do
    subject "test message 1"
    body    "welcome"
    created_at DateTime.new(1998,10,1)
  end

  factory :message2, :class=>:Message do
    subject "test message 2"
    body    "welcome again"
    created_at DateTime.new(1999,10,1)
  end
end
