namespace :check do
  namespace :census_employee do
    desc "check hired_on should not before dob for census employees"
    task :hired_on => [:environment] do
      count = 0
      CensusEmployee.all.each do |ce|
        if ce.dob >= ce.hired_on
          count += 1
          puts "ssn: #{ce.ssn} (dob: #{ce.dob}; hired_on: #{ce.hired_on})"
        end
      end
      puts "There are #{count} invalid census employees which dob before the hired_on."
    end
  end
end
