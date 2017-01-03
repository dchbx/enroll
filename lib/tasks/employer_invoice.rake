namespace :employer_invoice do
  desc "Generates Invoices for Initial and Conversion Employers"
  task generate: :environment do

    DO_NOT_INVOICE_LIST = ["520743373", "530026395", "550825492", "453987501", "530164970", "237256856",
     "611595539", "591640708", "521442741", "521766561", "522167254", "521826441", "530176859", "521991811",
     "522153746", "521967581", "147381250", "520968193", "521143054", "521943790", "520954741", "462199955",
     "205862174", "521343924", "521465311", "521816954", "020614142", "521132764", "521246872", "307607552",
     "522357359", "520978073", "356007147", "522315929", "521989454", "942437024", "133535334", "462612890",
     "541873351", "521145355", "530071995", "521449994"]

    @folder_name="DCEXCHANGE_#{TimeKeeper.date_of_record.strftime("%Y%m%d")}"
    
  	conversion_employers= Organization.where({
    :'employer_profile.profile_source' => 'conversion',
    :'employer_profile.plan_years' => { 
      :$elemMatch => {
          :"start_on" => { "$eq" => DateTime.parse("2016-08-01" ) } ,
          :"aasm_state".in =>  PlanYear::RENEWING_PUBLISHED_STATE 
        }
      }
    })

    new_employers = Organization.where({
      :'employer_profile.plan_years' => { 
       :$elemMatch => {
         :start_on =>  { "$eq" => DateTime.parse("2016-12-01" ) },
         :"aasm_state".in => PlanYear::PUBLISHED
       }}
    })

    # generate_invoices(conversion_employers, false)
    generate_invoices(new_employers, true)
   
    #Create a tar file 
    puts "creating a tar file now"
    	system("tar -zcvf #{@folder_name}.tar.gz #{@folder_name}")
    puts "Folder created!"

  end

  def generate_invoices(organizations, clean_up = nil )
    organizations.each do |org|
      unless DO_NOT_INVOICE_LIST.include?(org.fein) || !org.employer_profile.plan_years.renewing.first.try(:is_enrollment_valid?)
        if clean_up
          employer_invoice = EmployerInvoice.new(org,@folder_name)
          employer_invoice.save_and_notify_with_clean_up
        else
          employer_invoice = EmployerInvoice.new(org,@folder_name)
          employer_invoice.save_and_notify
        end
      end
    end
  end

  desc "Generates Invoices for Conversion Employers, given FEIN"
  task generate_by_fein: :environment do

    @folder_name="DCEXCHANGE_#{TimeKeeper.date_of_record.strftime("%Y%m%d")}"

    INVOICE_LIST_BY_FEIN = ["473216629", "475087382", "366110249", "202240552", "262226795", "471971506",
      "462036141", "272160999", "521854751", "204622047", "813521916", "383926625", "473186202", "743093659",
      "810814802", "464255260", "452915255", "521247182", "521038849", "812811250", "471465883", "000000083",
      "812982877", "522337206", "462691197", "811868912", "521250621", "473374252", "811512150", "311577362",
      "475557729", "522239757", "813257447", "274442154", "462311826", "263262732", "263311586", "530239116",
      "201347118", "813899317", "520913158", "475148006", "521195632", "463804477", "521009116", "454125843",
      "474206800", "461431787", "383890618", "611718234", "474145602", "462997613", "473752174", "810983298",
      "520972043", "870772231", "384013966", "471587361", "521361024", "463184561", "264392915", "810887188",
      "474934008", "811405300", "521457836", "260564431", "134256302"]

    organizations = Organization.where(:"fein".in => INVOICE_LIST_BY_FEIN)
    organizations.each do |org|
      employer_invoice = EmployerInvoice.new(org,@folder_name)
      employer_invoice.save_and_notify
    end
    puts "creating a tar file now"
      system("tar -zcvf #{@folder_name}.tar.gz #{@folder_name}")
    puts "Folder created!"
  end
end
