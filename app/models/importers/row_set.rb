module Importers
  module RowSet
    def row_iterator
      @spreadsheet.kind_of?(Roo::Excelx) ? :process_excel_rows : :process_csv_rows
    end

    def import!
      @out_csv << headers
      self.send(row_iterator)
    end

    def process_csv_rows
      (2..@spreadsheet.last_row).each do |idx|
        convert_row(@spreadsheet.row(idx))
      end
    end

    def process_excel_rows
      @sheet = @spreadsheet.sheet(0)
      (2..@sheet.last_row).each do |idx|
        convert_row(@sheet.row(idx))
      end
    end

    def convert_row(row)
      record_attrs = {}
      out_row = []
      row_mapping.each_with_index do |k, idx|
        value = row[idx]
        unless (k == :ignore) || value.blank?
          record_attrs[k] = value.to_s.strip.gsub(/\.0\Z/,"")
        end
      end

      record = create_model(record_attrs)

      import_details = []

      result = record.save
      if result
        if record.warnings.any?
          import_details = ["imported with warnings", JSON.dump(record.warnings.to_hash)]
        else
          import_details = ["imported", ""]
        end
      else
        import_details  = []
        import_details << ["import failed", JSON.dump(record.errors.to_hash)]
        import_details << ["warnings", JSON.dump(record.warnings.to_hash)] if record.warnings.any?
      end
      @out_csv << (row.map(&:to_s) + import_details)
    end
  end
end
