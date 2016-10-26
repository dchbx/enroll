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
          :"start_on" => { "$eq" => DateTime.parse("2016-10-01" ) } ,
          :"aasm_state".in =>  PlanYear::RENEWING_PUBLISHED_STATE 
        }
      }
    })

    new_employers = Organization.where({
      :'employer_profile.plan_years' => { 
       :$elemMatch => {
         :start_on =>  { "$eq" => DateTime.parse("2016-10-01" ) },
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

    INVOICE_LIST_BY_FEIN = ["812650064", "813667301", "274892867", "811988420", "472077927", "473481455", "522056857",
  "530196528", "460558330", "813468876", "473824624", "720921017", "530196592", "520901863", "521580305",
  "272630177", "743218001", "521403822", "474322713", "541697040", "472698509", "811380216", "620913689",
  "530208367", "474796144", "813260391", "522192070", "371831137", "364750789", "800934649", "473665266",
  "451236176", "530209637", "474020173", "464641685", "475239611", "813422012"]

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
