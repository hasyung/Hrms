module Excel
  class DepartmentWriter
    def initialize(data, path)
      @data = data
      @workbook = ::WriteExcel.new(path)
      @row = 1
    end

    def headers
      {
        3 => {
          3 => {name: '一正部门', col: 0},
          4 => {name: '一副部门', col: 1},
          5 => {name: '二正部门', col: 2}
        },
        4 => {
          4 => {name: '一副部门', col: 0},
          5 => {name: '二正部门', col: 1}
        },
        2 => {
          2 => {name: '分公司', col: 0},
          3 => {name: '一正部门', col: 1},
          4 => {name: '一副部门', col: 2},
          5 => {name: '二正部门', col: 3}
        }
      }
    end

    def write_excel
      check_exception
      serialized_data = Hash[@data.group_by(&:grade_id).sort] #排序让一正部门显示在第一个sheet里面
      serialized_data.each do |grade_id, departments|
        add_worksheet
        write_header(headers[grade_id])
        departments.each{|department| write_departments(grade_id, department)}
        reset_row
      end
      close_workbook
    end

    def add_worksheet
      @worksheet = @workbook.add_worksheet
    end

    def close_workbook
      @workbook.close
    end

    def write_departments(grade_id, department)
      col = col(grade_id, department)
      leafs_count = department.leafs_count

      if department.parent.grade_id != department.grade_id
        children_name = department.childrens.where(grade_id: department.grade_id).pluck(:name)
        name = children_name.empty? ? department.name : ("#{department.name}, #{children_name.join(', ')}")
        @worksheet.write(@row, col, name)
      end

      if leafs_count > 0
        @worksheet.merge_range(@row, col, @row + leafs_count - 1, col, '', format) if leafs_count > 1
        departments = department.childrens
        departments.each{|department| write_departments(grade_id, department)}
      end

      row_auto_incre if leafs_count == 0
    end

    def col(grade_id, department)
      key = department.grade_id
      headers[grade_id][key][:col]
    end

    def write_header(headers)
      headers.values.each_with_index{|cell_val, index| @worksheet.write(0, index, cell_val[:name])}
    end

    def format
      @workbook.add_format
    end

    private
    def check_exception
      data = @data.first

      return @data = data.childrens if data.depth == 1
      raise "Data can't export to xls" unless [2, 3, 4].include?(data.grade_id)
    end

    def row_auto_incre
      @row += 1
    end

    def reset_row
      @row = 1
    end
  end
end
