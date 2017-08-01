require_relative './../../common_meta/object'

module Excel
  class AnnuityTempWriter
    attr_reader :path, :filename

    def initialize(data)
      @data = data
      @filename = CGI::escape("年金人员列表_#{Time.now.to_i}.xls")
      @path = "#{Rails.root}/public/export/tmp/#{@filename}"
      @workbook = WriteExcel.new(@path)
      @row = 1
    end

    def headers
      {
        "data.employee_no"                                                                                                                  => "人员编码",
        "departments.select{|d| d.grade.name == 'branch_company' || d.grade.name == 'positive' || d.grade.name == 'scal'}.first.try(:name)" => "一级部门",
        "departments.select{|d| d.grade.name == 'deputy'}.first.try(:name)"                                                                 => "一副部门",
        "departments.select{|d| d.grade.name == 'secondly_positive'}.first.try(:name)"                                                      => "二正部门",
        "data.name"                                                                                                                         => "姓名",
        "data.contact.try(:mobile)"                                                                                                         => "手机号码",
        "data.identity_no"                                                                                                                  => "身份证编号",
        "data.annuity_cardinality"                                                                                                          => "年金基数",
        "data.annuity_status ? '在缴' : '退出'"                                                                                             => "年金状态"
      }
    end

    def write_excel
      add_worksheet
      write_header
      write_data unless @data.empty?
      close_workbook
      self
    end

    def write_data
      column_keys = headers.keys

      @data.each do |data|
        departments = data.department.parent_chain

        column_keys.each_with_index {|key, index| @worksheet.write(@row, index, eval(key))}
        row_auto_incre
      end
    end

    def close_workbook
      @workbook.close
    end

    def add_worksheet
      @worksheet = @workbook.add_worksheet
    end

    private
    def write_header
      array = headers.values
      array.each_with_index {|cell_val, index| @worksheet.write(0, index, cell_val)}
    end

    def row_auto_incre
      @row += 1
    end
  end
end
