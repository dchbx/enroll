module Notifier
  module Builders::OfferedProduct

    attr_reader :enrollment_service

    def offered_products
      benefit_application = load_benefit_application
      date = TimeKeeper.date_of_record.next_month.beginning_of_month
      enrollments = enrollment_service(benefit_application).hbx_enrollments_by_month(date)
      merge_model.offered_products = build_offered_products(enrollments)
    end

    def enrollment_service(benefit_application)
      @enrollment_service ||= BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(benefit_application)
    end

    def build_offered_products(enrollments)
      enrollments.group_by { |enrollment| enrollment["product_id"]}.collect do |product_id, enrollments|
        build_offered_product(product_id, enrollments)
      end
    end

    def build_offered_product(product_id, enrollments)
      offered_product = Notifier::MergeDataModels::OfferedProduct.new
      product = BenefitMarkets::Products::Product.find(product_id)
      offered_product.product_name = product.title
      offered_product.enrollments = build_enrollments(enrollments)
      offered_product
    end

    def fetch_enrollment(enrollment_id)
       HbxEnrollment.find enrollment_id
    end

    def build_enrollments(enrollments)
      enrollments.collect do |enrollment|
        enr = fetch_enrollment(enrollment["_id"])
        enrollment_model = Notifier::MergeDataModels::Enrollment.new
        enrollment_model.plan_name = enr.product.title
        enrollment_model.employee_responsible_amount = enr.total_employer_contribution
        enrollment_model.employer_responsible_amount = enr.total_employee_cost
        enrollment_model.premium_amount = enr.total_premium

        employee = enr.subscriber.person
        enrollment_model.subscriber = MergeDataModels::Person.new(first_name: employee.first_name, last_name: employee.last_name)
      
        dependents = enr.hbx_enrollment_members.reject{|member| member.is_subscriber}
        dependents.each do |dependent|
          enrollment_model.dependents << MergeDataModels::Person.new(first_name: dependent.person.first_name, last_name: dependent.person.last_name)
        end

        enrollment_model
      end
    end
  end
end