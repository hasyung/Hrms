module Excel
  class TransportFeeWriter
    def initialize(data, path)
      @data = data
      @path = path
      @book = Spreadsheet::Workbook.new
    end

    def write_nc_excel
      @sheet = @book.create_worksheet

      @sheet[0, 1] = "员工编号"
      @sheet[0, 2] = "交通费"

      @data.each_with_index do |transport_fee, index|
        @sheet[index + 1, 1] = transport_fee.employee_no
        @sheet[index + 1, 2] = transport_fee.total
      end

      @book.write @path
    end

    def write_approval_excel
      @sheet = @book.create_worksheet
      @book.write @path
    end
  end
end