module PdfTemplates
   class QualifyingLifeEventKind
   	 include Virtus.model
   	 
   	 attribute :title, String
   	 attribute :qle_on, Date
   	 attribute :start_on, Date
   	 attribute :end_on, Date
   	 attribute :reporting_deadline, Date
   	 attribute :qle_reported_on, Date
   end	
end	