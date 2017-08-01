module Excel
  class MonthDistributeBaseImporter < PerformanceImporterBase
    def initialize(file)
      super(file)
    end

    def call
      last_row = @data.last_row

      (2..last_row).each do |index|
        @current_row_data = @data.row(index)

        Employee.find(attributes[:id]).update(attributes) unless attributes.empty?
      end

      self
    end

    private
    def attributes
      @errors << @error_message and return {} unless attributes_valid?

      # puts "导入员工：#{@employee.name}的月度分配基数"
      {id: @employee.id, month_distribute_base: @current_row_data[headers[:month_distribute_base][:col_index]]}
    end

    def headers
      {
        employee_no: {
          col_index: 0,
          type: String,
          msg: '员工编号必须为文本类型; ',
          presence: true
        },
        employee_name: {
          col_index: 5,
          type: String,
          msg: '员工姓名必须为文本类型; ',
          presence: true
        },
        month_distribute_base: {
          col_index: 10,
          type: Float,
          msg: '考核结果必须为数字类型; ',
          presence: true
        }
      }
    end
  end
end