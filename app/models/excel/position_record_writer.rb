module Excel
  class PositionRecordWriter
    class << self
      def export(records)
        file_name = "#{Time.now.to_i}_岗位变更记录.xls"
        file_path = "#{Rails.root}/public/export/tmp/#{file_name}"

        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet

        #第一行
        [
          '变动时间', '姓名', '性别', '员工编号', '用工性质',
          '原部门', '原岗位','原通道', '原属地',
          '调入部门', '调入岗位', '新通道', '新属地',
          '发文文号', '备注'
        ].each_with_index do |title, index|
          sheet[0, index] = title
        end

        counter = 1
        records.find_each do |record|
          sheet[counter, 0]  = record.change_date.to_s
          sheet[counter, 1]  = record.employee_name
          sheet[counter, 2]  = record.gender_name
          sheet[counter, 3]  = record.employee_no
          sheet[counter, 4]  = Employee::LaborRelation.where(id: record.labor_relation_id).first.try(:display_name)
          sheet[counter, 5]  = record.pre_department_name
          sheet[counter, 6]  = record.pre_position_name
          sheet[counter, 7]  = record.pre_channel_name
          sheet[counter, 8]  = record.pre_location
          sheet[counter, 9]  = record.department_name
          sheet[counter, 10] = record.position_name
          sheet[counter, 11] = record.channel_name
          sheet[counter, 12] = record.location
          sheet[counter, 13] = record.oa_file_no
          sheet[counter, 14] = record.note

          counter += 1
        end

        book.write file_path

        { path: file_path, filename: file_name }

      end
    end
  end
end
