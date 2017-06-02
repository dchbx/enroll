FactoryGirl.define do
  factory :notice_trigger do
    trait :out_of_pocket_notice do
      notice_template "notices/shop_employer_notices/out_of_pocket_notice.html.erb"
      notice_builder "ShopEmployerNotices::OutOfPocketNotice"
      mpi_indicator "MPI"
    end
  end

end
