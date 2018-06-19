module Notifier
   class MergeDataModels::SpecialEnrollmentPeriod
     include Virtus.model

     attribute :title, String
     attribute :qle_reported_on, String
     attribute :start_on, String
     attribute :end_on, String
     attribute :submitted_at, String

     def self.stubbed_object
       Notifier::MergeDataModels::SpecialEnrollmentPeriod.new({
         title: 'Married',
         qle_reported_on: (TimeKeeper.date_of_record - 10.days).strftime('%m/%d/%Y'),
         start_on: (TimeKeeper.date_of_record - 10.days).strftime('%m/%d/%Y'),
         end_on: (TimeKeeper.date_of_record + 20.days).strftime('%m/%d/%Y'),
         submitted_at: (TimeKeeper.datetime_of_record).strftime('%m/%d/%Y')
         })
     end
   end
end