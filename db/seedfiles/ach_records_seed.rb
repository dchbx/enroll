puts "*"*80
puts "::: Generating ACH Records"
errors = 0
records = 0

File.readlines('./db/seedfiles/FedACHdir.txt').each do |line|
  section = line[0...71]
  routing_number = section[0...9]
  bank_name = section[10...71].scan(/\D/).join().rstrip
  if AchRecord.create!(routing_number: routing_number, bank_name: bank_name)
    records += 1
  else
    errors += 1
  end
end

puts "Created #{records} record(s) with #{errors} error(s)"
