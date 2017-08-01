require 'spreadsheet'

module Excel
  class RewardImporter
    def self.import(type_symbol, file_path, month)
      field = type_symbol.to_s.gsub("import_", "").to_sym
      sheet = get_sheet(file_path)
      error_names, error_count = [], 0

      # 不删除记录表
      # 导入的奖金只有预算外奖励是需要累加的, 其他的都是替换

      @employees = Employee.includes(department: :department_salaries)

      Reward.transaction do
        total_reward = 0

        sheet.each_with_index do |row, index|
          next if row[0].to_s.include?("姓名")
          employee = @employees.select{|e| e.name == row[0]}.first
          @first_department = employee.department.parent_chain.first if employee && @first_department.blank?

          if employee.blank?
            error_names << row[0]
            error_count += 1
          end
          if employee && @first_department != employee.department.parent_chain.first
            return {result: {type: '导入失败', messages: '文件包含多个部门员工奖励', desc: "文件包含多个部门员工奖励"}, is_succ: false}
          end

          total_reward += row[2].to_f
        end

        if error_count > 0
          return {result: {
            success_count: sheet.count - error_count - 1,
            error_count: error_count,
            error_names: error_names,
            type: '导入失败',
            messages: '员工找不到',
            desc: '下列员工找不到'
            },
            is_succ: false
          }
        end

        standard = @first_department.department_salaries.select{|s| s.month == month}.first.try(field).to_f
        if [:cash_fine_fee,:off_budget_fee, :save_oil_fee].exclude?(field) && standard != total_reward
          return {result: {type: '导入失败', messages: '奖金与部门分配不一致', desc: "奖金与部门分配不一致"}, is_succ: false}
        end

        @record_ids = []
        sheet.each_with_index do |row, index|
          next if row[0].to_s.include?("姓名")

          @employee_name = row[0]
          @employee_no   = row[1].to_s
          @employee = @employees.select{|e| e.name == @employee_name}.first

          hash = {
            employee_name: @employee_name,
            employee_no:   @employee_no,
            employee_id:   @employee.id,
            month:         month
          }

          @record = RewardRecord.find_or_create_by(hash)
          @record_ids << @record.id

          if type_symbol == :import_off_budget_fee
            @record.increment!(field, row[2].to_f)
          else
            @record.update(field =>  row[2].to_f)
          end
        end
        RewardRecord.joins(employee: :department).where("departments.full_name like '#{@first_department.name}%' and 
            reward_records.month = '#{month}' and reward_records.id not in (?)", @record_ids).update_all(field => 0)
      end
      {result: {messages: "导入成功"}, is_succ: true}
    end

    private
    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end
