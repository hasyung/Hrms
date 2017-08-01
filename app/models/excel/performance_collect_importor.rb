require 'spreadsheet'

module Excel
	class PerformanceCollectImportor
    attr_accessor :errors

    COLUMNS = %w(employee_id employee_name employee_no department_name 
      position_name channel assess_time result sort_no employee_category 
      category assess_year category_name department_id is_leader)

    def initialize path
      @sheet = Spreadsheet.open(path)
      @errors = []
    end

    def import
    	Performance.transaction do
        @employee_hash = Employee.all.index_by(&:employee_no)
       
        @performances = Performance.select('id','employee_no','assess_time').index_by{|performance| "#{performance.employee_no}_#{performance.assess_time}"}
        values, performance_ids = [], []
        categories = CodeTable::Category.all

    		@sheet.each_with_index do |row, index|
    			next if index == 0
          employee = @employee_hash[row[0]]
          next if employee.nil?
    			
          performance = @performances["#{row[0]}_#{row[7]}"]

          performance_ids << performance.id unless performance.nil?
          
          values << [employee.id, employee.name, row[0], row[2], row[3], row[4], row[7],
            row[8], row[9], row[5], (row[6] == "年度" ? "year" : "month"), row[7].split("-").first,
            row[6], employee.department_id, employee.is_leader?(categories)]
          if index % 500 == 0
            Performance.where(id: performance_ids).delete_all
            Performance.import(COLUMNS, values, validate: false)
            values, performance_ids = [], []
            next
          end
    	  end
        if values.size != 0
          Performance.where(id: performance_ids).delete_all
          Performance.import(COLUMNS, values, validate: false)
        end
        
      end
    end

    def valid_format
      @sheet.each_with_index do |row, index|
        next if index == 0
        row.each_with_index do |column, column_index|
          if [0,1,2,3,4,5,6,7].include?(column_index) && row[column_index].nil?
            @errors << "第#{index+1}行，填写不完整！"
            return false
          end
        end
        # employee = Employee.find_by(employee_no:row[0])
        # if employee.nil?
          # @errors << "第#{index+1}行，人员不存在！"
          # return false
          # next
        # end
        # positions = employee.positions
        # unless positions.map(&:name).include?(row[3])
        #   @errors << "第#{index+1}行，人员岗位填写错误！"
        #   return false
        # end
        # unless positions.select{|p| p.name == row[3]}.map(&:department).map(&:full_name).include?(row[2])
        #   @errors << "第#{index+1}行，人员部门填写错误！"
        #   return false
        # end
        # if row[9].nil? && row[8].nil?
        #   @errors << "第#{index+1}行，考核结果和排序至少填一项！"
        #   return false
        # end
        if row[5] != "干部" && row[5] != "员工"
          @errors << "第#{index+1}行，员工分类只能填写“干部”和“员工”！"
          return false
        end
        if row[6] != "年度" && row[6] != "月度"
          @errors << "第#{index+1}行，考核类型填写错误！"
          return false
        end
        if row[7].split("-").size != 3
          @errors << "第#{index+1}行，考核时间格式填写错误，分隔符必须是'-'！"
          return false
        end
        if row[8].present? && row[8] != "优秀" && row[8] != "良好" && row[8] != "合格" && row[8] != "待改进" && row[8] != "不合格" && row[8] != "无"
          @errors << "第#{index+1}行，考核结果填写错误！"
          return false
        end
      end
      return true
    end
	end
end