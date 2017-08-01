require "spreadsheet"

module Excel
  class SpecialStateWriter
    attr_reader :filename, :path

    def initialize(data)
      @datas = data
      @filename = "#{Time.now.to_i}_异动信息汇总表.xls"
      @path = "#{Rails.root}/public/export/tmp/#{@filename}"
      @book = Spreadsheet::Workbook.new
      @sheet = @book.create_worksheet
    end

    def write_excel
      ["员工编号", "员工姓名", "分公司", "一正部门", "一副部门", "二正部门", "岗位", "异动性质", "异动操作时间", "异动地点", "异动开始时间", "异动结束时间", "文件编号", "停飞原因"].each_with_index do |name, column|
        @sheet[0, column] = name
      end

      counter = 0
      @datas.find_each do |data|
        counter += 1
        employee = Employee.unscoped.find_by(id:data.employee_id)
        next if employee.nil?
        department = employee.department
        branch_company = ''
        one_main_department = ''
        one_deputy_department = ''
        two_main_department = ''
        department.full_name.split('-').each do |d_name|
          case Department.find_by(name: d_name).grade_id
          when 2
            branch_company        = d_name
          when 3
            one_main_department   = d_name
          when 4
            one_deputy_department = d_name
          when 5
            two_main_department   = d_name
          end
        end
        puts employee.id
        @sheet[counter, 0] = employee.employee_no
        @sheet[counter, 1] = employee.name
        @sheet[counter, 2] = branch_company
        @sheet[counter, 3] = one_main_department
        @sheet[counter, 4] = one_deputy_department
        @sheet[counter, 5] = two_main_department
        @sheet[counter, 6] = employee.try(:master_position).try(:name)
        @sheet[counter, 7] = data.special_category
        @sheet[counter, 8] = data.updated_at.strftime("%Y-%m-%d")
        @sheet[counter, 9] = data.special_location
        @sheet[counter, 10] = data.special_date_from.strftime("%Y-%m-%d")
        @sheet[counter, 11] = data.special_date_to.nil? ? "" : data.special_date_to.strftime("%Y-%m-%d")
        @sheet[counter, 12] = data.file_no
        @sheet[counter, 13] = data.stop_fly_reason

      end

      @book.write path

      {
        path: @path,
        filename: @filename
      }
    end

  end
end