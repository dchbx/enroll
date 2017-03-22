module Api
  module V1
    class SlcspController < ActionController::Base
      def plan
        begin
          request_xml = request.body.read
          parsed_request = HappyMapper.parse(request_xml)
          @plan = find_slcsp(Date::strptime(parsed_request.coverage_start, "%Y%m%d"))

          render :template => 'shared/_plan.xml.builder', :layout => false, :status => :ok
        rescue Exception => e
          render :xml => "<errors><error>#{e.message}</error></errors>", :status => :unprocessable_entity
        end
      end

      private
      def find_slcsp(coverage_start)

        benefit_coverage_period = Organization.where(dba:'DCHL').first.hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |benefit_coverage_period|
          benefit_coverage_period.start_on <= coverage_start && benefit_coverage_period.end_on >= coverage_start
        end

        raise "SLCSP could not be found" if benefit_coverage_period.nil?

        Plan.find(benefit_coverage_period.slcsp) rescue "SLCSP could not be found"
      end
    end
  end
end
