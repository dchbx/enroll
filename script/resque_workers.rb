require 'resque/tasks'

ENV['QUEUE'] = "*"
Rake::Task['resque:work'].invoke