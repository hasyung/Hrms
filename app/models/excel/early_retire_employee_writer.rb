require_relative './../../common_meta/object'

module Excel
  class EarlyRetireEmployeeWriter
    attr_reader :path, :filename

    def initialize(data)
      @data = data
      @filename = CGI::escape("#{Time.now.to_i}离开人员明细.xls")
      @path = "#{Rails.root}/public/export/tmp/#{@filename}"
      @workbook = WriteExcel.new(@path)
      @row = 1
    end

    def headers
      {
        "data.department.split('-')[0]" => "大部",
        "data.department.split('-')[1]" => "一级部门",
        "data.department.split('-')[2]" => "二级部门",
        "data.name" => "姓名",
        "data.employee_no" => "员工号",
        "data.file_no" => "文件编号",
        "data.change_date.try(:to_s, :db)" => "退养时间",
        "data.position" => "岗位",
        "data.labor_relation" => "用工性质",
        "data.channel" => "通道",
        "data.gender" => "性别",
        "data.birthday.try(:to_s, :db)" => "出生时间",
        "data.identity_no" => "身份证号",
        "data.join_scal_date.try(:to_s, :db)" => "到岗时间",
        "data.remark" => "备注"
      }
    end

    def write_excel
      add_worksheet
      write_header
      write_employee unless @data.empty?
      close_workbook
      self
    end

    def add_worksheet
      @worksheet = @workbook.add_worksheet
    end

    def write_header
      headers.values.each_with_index{|cell_val, index| @worksheet.write(0, index, cell_val)}
    end

    def write_employee
      column_keys = headers.keys

      @data.each do |data|
        column_keys.each_with_index{|key, index| @worksheet.write(@row, index, eval(key))}
        row_auto_incre
      end
    end

    def close_workbook
      @workbook.close
    end

    def row_auto_incre
      @row += 1
    end
  end
end
