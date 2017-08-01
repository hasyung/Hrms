module Excel
  class FamilyMemberImportor
    COLUMNS = %w(employee_id name birthday gender identity_no relation_type relation)

    def self.import(file_path)
      book = get_book(file_path)
      sheet = book.worksheet 0

      Employee::FamilyMember.transaction do
        values, error_count, succ_count, error_no = [], 0, 0, []
        employees = Employee.unscoped.all

        sheet.each_with_index do |row, index|
          next if index == 0

          employee = employees.select{|e| e.employee_no == row[0]}.first
          if employee.blank?
            error_no << row[0]
            error_count += 1
            next
          end

          relation = ''
          case row[3]
          when '配偶'
            relation = 'lover'
          when '子女'
            relation = 'children'
          else
            relation = 'other'
          end

          succ_count += 1
          values << [employee.id, row[1], row[4], row[2], row[6], row[3], relation]
        end

        Employee::FamilyMember.delete_all
        Employee::FamilyMember.import(FamilyMemberImportor::COLUMNS, values, validate: false)

        {
          success_count: succ_count,
          error_count: error_count,
          error_names: error_no
        }
      end
    end

    def self.get_book(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
    end

  end
end
