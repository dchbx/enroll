# require 'rails_helper'
#
# RSpec.shared_examples "a rate reference" do |attributes|
#   attributes.each do |attribute, value|
#     it "should return #{value} from ##{attribute}" do
#       expect(subject.send(attribute)).to eq(value)
#     end
#   end
# end
#
# RSpec.describe 'Load Rating Regions Task', :type => :task do
#
#   context "rating_area:update_rating_areas" do
#     before :all do
#       Rake.application.rake_require "tasks/migrations/load_rating_area"
#       Rake::Task.define_task(:environment)
#     end
#
#     before :context do
#       invoke_task
#     end
#
#     context "it creates RatingArea elements correctly" do
#       subject { RatingArea.first }
#       it_should_behave_like "a rate reference", { zip_code: "01001",
#                                                   county_name: "Hampden",
#                                                   zip_code_in_multiple_counties: false,
#                                                   rating_area: "Rating Area 1"
#                                                 }
#       # Which simply replaces all of these:
#       #
#       # it { is_expected.to have_attributes(zip_code: "01001") }
#       # it { is_expected.to have_attributes(county: "Hampden") }
#       # it { is_expected.to have_attributes(multiple_counties: false) }
#       # it { is_expected.to have_attributes(rating_area: "Rating Area 1") }
#       #
#       # Which is just equilavent to a series of these:
#       #
#       # it "assigns the correct zip code" do
#       #   expect(subject.zip_code).to eq('01001')
#       # end
#     end
#
#     context "it handles the case where multiple counties exist in the same Zip Code" do
#       let(:rating_areas_by_zip) { RatingArea.where(zip_code: "01002") }
#       context "first rate reference for zip code" do
#         subject { rating_areas_by_zip.first }
#         it_should_behave_like "a rate reference", { zip_code: "01002",
#                                                     county_name: "Hampshire",
#                                                     zip_code_in_multiple_counties: true,
#                                                     rating_area: "Rating Area 1"
#                                                   }
#       end
#
#       context "second rate reference for zip code" do
#         subject { rating_areas_by_zip.second }
#         it_should_behave_like "a rate reference", { zip_code: "01002",
#                                                     county_name: "Franklin",
#                                                     zip_code_in_multiple_counties: true,
#                                                     rating_area: "Rating Area 1"
#                                                   }
#       end
#     end
#
#     private
#
#     def invoke_task
#       Rake::Task["load_rating_area:update_rating_areas"].invoke
#     end
#   end
# end
