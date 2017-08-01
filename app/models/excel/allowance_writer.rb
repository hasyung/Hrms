require "spreadsheet"

module Excel
  class AllowanceWriter
    def initialize(data, path)
      @data = data
      @path = path
      @book = Spreadsheet::Workbook.new
    end

    def write_nc
      @sheet = @book.create_worksheet
      @book.write @path
    end

    def write_approval
      @sheet = @book.create_worksheet
      @book.write @path
    end

    def write_temp
      @sheet = @book.create_worksheet(name: "总表")

      @sheet[0, 0] = "部门"
      @sheet[0, 1] = "姓名"
      @sheet[0, 2] = "人员编码"
      @sheet[0, 3] = "高温津贴"
      @sheet[0, 4] = "帐套"

      @has_temp_ids = @data.map(&:employee_id)
      @hash = @data.index_by(&:employee_name)

      # 导出的xls的顺序按照排序规则排序
      @employees = Employee.includes(:department, :positions).where(id: @has_temp_ids).order("departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no")
      @row = 1
      @employees.each do |employee|
        # 没有对应的高温补贴直接跳过
        next if @hash[employee.name].nil?

        @sheet[@row, 0] = employee.department.name
        @sheet[@row, 1] = employee.name
        @sheet[@row, 2] = employee.labor_relation.display_name
        @sheet[@row, 3] = @hash[employee.name].try(:temp)
        @sheet[@row, 4] = employee.salary_set_book

        @row += 1
      end

      @sheet = @book.create_worksheet(name: "公司")
      @sheet[0, 0] = "部门"
      @sheet[0, 1] = "高温津贴(元)"
      @sheet[0, 2] = "备注"

      # 按照大部门汇总
      @allowances = Allowance.includes(:employee => :department).order("departments.d1_sort_no")
      @allowances = @allowances.where("employees.salary_set_book <> '重庆合同制' AND employees.salary_set_book <> '重庆合同工'")
      @row = 1

      @allowances.group_by {|x|x.employee.try(:department).try(:full_name).try(:split, "-").try(:first)}.each do |dep_name, array|
        next unless dep_name
        @total = 0

        array.each do |allowance|
          @sheet[@row, 0] = dep_name
          @sheet[@row, 1] = allowance.temp.to_f
          @total += allowance.temp.to_f

          @row += 1
        end

        @row += 1
        @sheet[@row, 0] = dep_name + " 汇总"
        @sheet[@row, 1] = @total
      end

      @sheet = @book.create_worksheet(name: "重庆")
      @sheet[0, 0] = "部门"
      @sheet[0, 1] = "高温津贴(元)"
      @sheet[0, 2] = "备注"

      # 重庆合同工和重庆合同制
      @allowances = @data.includes(:employee => :department).order("departments.d1_sort_no")
      @allowances = @allowances.where("employees.salary_set_book = '重庆合同制' OR employees.salary_set_book = '重庆合同工'")
      @row = 1

      @allowances.group_by {|x|x.employee.try(:department).try(:full_name).try(:split, "-").try(:first)}.each do |dep_name, array|
        next unless dep_name
        @total = 0

        array.each do |allowance|
          @sheet[@row, 0] = dep_name
          @sheet[@row, 1] = allowance.temp.to_f
          @total += allowance.temp.to_f

          @row += 1
        end

        @row += 1
        @sheet[@row, 0] = dep_name + " 汇总"
        @sheet[@row, 1] = @total
      end

      @sheet = @book.create_worksheet(name: "内部包干")
      @sheet[0, 0] = "部门"
      @sheet[0, 1] = "高温津贴(元)"
      @sheet[0, 2] = "备注"
      @sheet[1, 0] = "SCAL汇总"
      @sheet[2, 0] = "总计"
      @sheet[3, 0] = "制表:"
      @sheet[3, 1] = "审核:"
      @sheet[3, 1] = "科室领导:"
      @sheet[5, 2] = "人力资源部"
      @sheet[6, 2] = Time.new.strftime("%m/%d/%y")

      @book.write @path
    end
  end
end
