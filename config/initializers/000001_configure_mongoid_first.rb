# For some totally bazarre reason the inclusion of react.js causes the mongoid
# initializer to not get fired before we hit the translation backend or the
# plan lookups
Rails.application.initializers.detect { |ini| ini.name == "mongoid.load-config" }.run
