require 'csv'

namespace :reports do
  namespace :shop do
    desc "List duplicate hbx_enrollments"
    task :duplicate_enrollment_list => :environment do
      families=Family.all
      field_names  = %w(
          enrollment_hbx_id
          subscriber_hbx_id
          effective_on_date
          aasm_state
          kind
          coverage_kind
        )
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/duplicate_hbx_enrollment.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        families.each do |family|
          hbx_array=family.active_household.hbx_enrollments.active.all.map{|a|[a.aasm_state,a.kind,a.coverage_kind,a.effective_on]}
          unless hbx_array.detect{|a| hbx_array.count(a)>1}.nil?
            duplicate_elements=hbx_array.detect{|a| hbx_array.count(a)>1}
            hbx_array.select{|a| a==duplicate_elements}.each do  |i|
              index=hbx_array.index(i)
              enrollment=family.active_household.hbx_enrollments.active.all[index]
              puts family.id
              csv << [
                      enrollment.hbx_id,
                      enrollment.subscriber.person.hbx_id,
                      enrollment.effective_on,
                      enrollment.aasm_state,
                      enrollment.kind,
                      enrollment.coverage_kind
                     ]

            end
            break
          end
         end
      end
      puts "There is no duplicate enrollments"
    end
  end
end