require 'rails_helper'

class FakesController < ApplicationController
  include DataTablesSearch
end

describe FakesController, dbclean: :after_each do

  let!(:family_1) { FactoryGirl.create(:family, :with_primary_family_member)}
  let!(:family_2) { FactoryGirl.create(:family, :with_primary_family_member)}
  describe "#search_families" do

    before do
      @families = Family.all
      Family.first.primary_applicant.person.update_attributes(last_name: "scofield")
    end

    it "should return all families unless search string is present" do
      expect(subject.search_families("", @families)).to eq @families
    end

    it "should return matched families if search string is present" do
      expect(subject.search_families("scofield", @families).size).to eq 1
    end
  end

  describe "#input_sort_request" do

    context "when user not opted to sort" do
      let(:params) {
      }

      it "should return nil when not sorted" do
        expect(subject.input_sort_request).to eq [nil, nil]
      end
    end

    context "when user opted to view sorted results" do

      shared_examples_for "sorted_results" do |col_num, order, sorted_by|

        let!(:params) {
          {
            :"order" => {
              "0" => {
                column: "#{col_num}",
                dir: "#{order}"
              }
            }
          }
        }

        before do
          allow(subject).to receive(:params).and_return params
        end

        it "should return the column parameter & order type" do
          expect(subject.input_sort_request).to eq [sorted_by, order]
        end
      end

      it_behaves_like "sorted_results", "4", "asc", :min_verification_due_date_on_family
      it_behaves_like "sorted_results", "4", "desc", :min_verification_due_date_on_family
      it_behaves_like "sorted_results", "6", "asc", :review_status
      it_behaves_like "sorted_results", "6", "desc", :review_status

    end
  end

  describe "#sorted_families" do
    before do
      @families = Family.all
    end

    it "should return families" do
      expect(subject.sorted_families(nil, nil, @families)).to eq @families
    end

    it "should sort by min_verification_due_date_on_family if received it as attributes" do
      expect(subject.sorted_families(:min_verification_due_date_on_family, "asc", @families)).to eq @families.sort_by(&:min_verification_due_date_on_family)
    end

    it "should sort by review_status if received it as attributes" do
      expect(subject.sorted_families(:review_status, "asc", @families)).to eq @families.sort_by(&:review_status)
    end

    it "should sort in ascending order if received it in attributes" do
      expect(subject.sorted_families(:review_status, "asc", @families)).to eq @families.sort_by(&:review_status)
    end

    it "should sort in descending order if received it in attributes" do
      expect(subject.sorted_families(:review_status, "desc", @families)).to eq @families.sort_by(&:review_status).reverse
    end
  end
end
