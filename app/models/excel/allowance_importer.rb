require 'spreadsheet'

module Excel
  class AllowanceImporter
    def self.import_airline_practice(file_path, month)
      import(:airline_practice, file_path, month)
    end

    def self.import_follow_plane(file_path, month)
      import(:follow_plane, file_path, month)
    end

    def self.import_permit_sign(file_path, month)
      import(:permit_sign, file_path, month)
    end

    def self.import_work_overtime(file_path, month)
      import(:work_overtime, file_path, month)
    end

    def self.import_property_subsidy(file_path, month)
      import(:property_subsidy, file_path, month)
    end

    def self.import_import_on_duty_subsidy(file_path, month)
      import(:import_on_duty_subsidy, file_path, month)
    end

    def self.import_with_parking_subsidy(file_path, month)
      import(:with_parking_subsidy, file_path, month)
    end

    def self.import_annual_audit_subsidy(file_path, month)
      import(:annual_audit_subsidy, file_path, month)
    end

    def self.import_material_handling_subsidy(file_path, month)
      import(:material_handling_subsidy, file_path, month)
    end

    private

    def self.import(type_symbol, file_path, month)
      sheet = get_sheet(file_path)

      Allowance.transaction do
        sheet.each_with_index do |row, index|
          next if row[0].blank?
          next if row[0].include?("姓名")

          @employee_name = row[0]
          @employee_no = row[1]

          hash = {
            employee_name: @employee_name,
            employee_no: @employee_no,
            month: month
          }

          record = AllowanceRecord.find_or_create_by(hash)
          record.update(type_symbol => row[2].to_f)
        end
      end
    end

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end
