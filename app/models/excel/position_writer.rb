require_relative './../../common_meta/object'

module Excel
  class PositionWriter
    attr_reader :path, :filename

    def initialize(data)
      @data = data
      @filename = CGI::escape("#{Time.now.to_i}岗位.xls")
      @path = "#{Rails.root}/public/export/tmp/#{@filename}"
      @workbook = WriteExcel.new(@path)
      @row = 1
    end

    def headers
      {
        "name" => "岗位名称",
        "department.full_name" => "部门名称",
        "channel.display_name" => "通道",
        "budgeted_staffing" => "编制",
        "staffing" => "在岗人数",
        "schedule.display_name" => "工时制度",
        "oa_file_no" => "文件OA号"
      }
    end

    def write_excel
      add_worksheet
      write_header
      write_positions unless @data.empty?
      close_workbook
      self
    end

    def close_workbook
      @workbook.close
    end

    def write_positions
      column_keys = headers.keys

      @data.each do |data|
        column_keys.each_with_index {|key, index| @worksheet.write(@row, index, data.send_methods(key))}
        row_auto_incre
      end
    end

    def add_worksheet
      @worksheet = @workbook.add_worksheet
    end

    private
    def write_header
      headers.values.each_with_index {|cell_val, index| @worksheet.write(0, index, cell_val)}
    end

    def row_auto_incre
      @row += 1
    end
  end
end
