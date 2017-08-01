module Excel
  class SetBookExportor
    class << self
       def export_change_record()
         book = Spreadsheet.open("#{Rails.root}/public/template/setbook_change_record.xls")
         sheet0 = book.worksheet 0
         sheet1 = book.worksheet 1

         @create_records = SetBook::ChangeRecord.where(category: 'create')
         @create_records.each_with_index do |record, index|
           employee = record.employee
           sheet0[index+3, 0] = record.new_deparment_name
           sheet0[index+3, 1] = record.new_deparment_set_book_no
           sheet0[index+3, 2] = employee.name
           sheet0[index+3, 3] = employee.employee_no
           sheet0[index+3, 4] = employee.identity_no
           sheet0[index+3, 5] = record.new_bank_no
           sheet0[index+3, 6] = employee.labor_relation.try(:display_name)
           sheet0[index+3, 7] = record.new_employee_category
           sheet0[index+3, 8] = record.new_salary_category
           sheet0[index+3, 9] = employee.location
         end

        @update_records = SetBook::ChangeRecord.where(category: 'update')
        @update_records.each_with_index do |record, index|
          employee = record.employee
          sheet1[index+3, 0]  = employee.employee_no
          sheet1[index+3, 1]  = employee.name
          sheet1[index+3, 2]  = record.new_bank_no
          sheet1[index+3, 3]  = record.old_deparment_name
          sheet1[index+3, 4]  = record.new_deparment_name
          sheet1[index+3, 5]  = record.new_deparment_set_book_no
          sheet1[index+3, 6]  = record.old_salary_category
          sheet1[index+3, 7]  = record.new_salary_category
          sheet1[index+3, 8]  = ""
          sheet1[index+3, 9]  = ""
          sheet1[index+3, 10] = record.new_employee_category
        end

        SetBook::ChangeRecord.delete_all

        filename = "帐套变更导出表.xls"
        filepath = "#{Rails.root}/public/export/tmp/#{filename}"
        book.write(filepath)
        {
          path: filepath,
          filename: filename
        }
       end
    end
  end
end
