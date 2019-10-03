# Output the expected runtimes from a re-sorted test log over a number of
# evenly distributed processes (currently 3).
# Relies on a previous run of resort_test_runtimes.rb against a valid test
# data set.

file_lines = File.read(File.join(File.dirname(__FILE__), "../resorted_times.log"))

timed_lines = file_lines.split("\n").map do |f_line|
  name, time_str = f_line.split(":")
  [time_str.to_f, name]
end.sort_by { |tl| tl.first }.reverse

total_time = timed_lines.inject(0.0) do |acc, tl|
  acc + tl.first
end

puts "#{(total_time/60.0)} minutes total"

proc_sets = Array.new(4) { Array.new }

timed_lines.each do |item|
  proc_sets[0] << item
  proc_sets = proc_sets.sort_by { |ps| (ps.inject(0.0) { |acc, pse| acc + pse.first }) }
end

ps_length = proc_sets.map { |ps| ps.length }

proc_sets.each do |ps|
  set_time = ps.inject(0.0) { |acc, pse| acc + pse.first } 
  puts "#{ps.length} test files - #{set_time/60.0} minutes"
end
