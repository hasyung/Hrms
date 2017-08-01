module Excel
  class PerformanceImporter < PerformanceImporterBase
    def initialize(file, assess_time, category)
      @assess_time = assess_time.to_date
      @category = category
      @assess_year = @assess_time.year.to_s

      super(file)
    end

    def call
      (1..@last_row).each do |index|
        @current_row_data = @data.row(index)

        Performance.create(attributes) unless attributes.empty?
      end

      self
    end

    private
    def attributes
      performace_attr = performace_attributes

      @errors << @error_message and return {} unless attributes_valid?
      @errors << @error_message and return {} if (@category == 'month' && !month_base_valid?(performace_attr))

      #puts "导入员工：#{@employee.name}的绩效考核"
      {assess_time: @assess_time, category: @category, assess_year: @assess_year}.merge(employee_attributes).merge(performace_attr)
    end

    def employee_attributes
      {
        employee_id: @employee.id,
        employee_name: @employee.name,
        employee_no: @employee.employee_no,
        department_name: @employee.department.full_name,
        position_name: @employee.master_position.name,
        channel: @employee.channel.try(:display_name),
        employee_category: @employee.pcategory
      }
    end

    def month_base_valid?(performace_attr)
      month_distribute_scal = (performace_attr[:department_distribute_result].to_f + performace_attr[:department_reserved].to_f) / performace_attr[:month_distribute_base]
      scal = {'优秀' => (1.2..1.5), '良好' => (1.1..1.2), '合格' => (0.7..1), '待改进' => (0..0.5), '不合格' => [0]}[performace_attr[:result]]
      @error_message = "#{@employee.name}的绩效薪酬总额与绩效等级不符"

      return true unless performace_attr[:result] # 当没有打绩效，视为无效，让验证通过
      return false unless scal.include?(month_distribute_scal)
      return true
    end

    def performace_attributes
      (headers.except(:employee_no, :employee_name)).inject({}) do |attributes, (attr_name, value)|
        attributes[attr_name] = @current_row_data[value[:col_index]]
        attributes
      end
    end

    def headers
      return month_headers if @category == 'month'
      return year_headers
    end

    def month_headers
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
          col_index: 7,
          type: Float,
          msg: '月度分配基数必须为数字类型; ',
          presence: true
        },
        result: {
          col_index: 8,
          type: String,
          msg: '考核结果必须为文本类型; ',
          presence: false
        },
        department_distribute_result: {
          col_index: 9,
          type: Float,
          msg: '部门当月分配结果必须为数字类型; ',
          presence: false
        },
        department_reserved: {
          col_index: 10,
          type: Float,
          msg: '部门留存分配结果必须为数字类型; ',
          presence: false
        }
      }
    end

    def year_headers
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
        result: {
          col_index: 10,
          type: String,
          msg: '考核结果必须为文本类型; ',
          presence: false
        },
        sort_no: {
          col_index: 11,
          type: String,
          msg: '考核排序结果必须为文本类型',
          presence: false
        }
      }
    end
  end
end
