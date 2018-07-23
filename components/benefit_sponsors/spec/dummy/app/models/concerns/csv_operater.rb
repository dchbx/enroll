module CsvOperater 
  extend ActiveSupport::Concern 

  module ClassMethods
    def convert_csv(arr)
      row = arr.count
      column = arr.first.count

      inversion = Array.new(column){ Array.new(row, 0)}
      row.times do |r|
        column.times do |c|
          inversion[c][r] = arr[r][c]
        end
      end
      inversion
    end
  end
end
