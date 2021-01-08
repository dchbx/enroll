require 'ruumba/rake_task'

Ruumba::RakeTask.new(:ruumba) do |t|
  t.dir = %w(app/views)

  # You can specify CLI options too:
  t.options = { arguments: %w[-c .ruumba.yml] }
  puts("running ruumba")
end