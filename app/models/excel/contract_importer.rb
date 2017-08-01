require 'spreadsheet'

module Excel
  class ContractImporter
    attr_reader :errors, :sheet

    def initialize(file_path)
      @sheet = Spreadsheet.open(file_path).worksheet(0)
      @errors = []
    end

    def parse_data
      labor_relations = Employee::LaborRelation.all.map(&:display_name)

      @sheet.each_with_index do |row, index|
        next if index == 0
        @employee = Employee.unscoped.where(employee_no: row[0], name: row[6]).first

        unless @employee.present?
          @errors << "第#{index + 1}行，花名册不存在该员工，请确认员工工号与姓名正确对应"
          next
        end

        unless labor_relations.include?row[7]
          @errors << "第#{index + 1}行，用工性质填写错误"
        end

        if row[10].blank? || row[8].blank? || row[7].blank? || row[11].blank?
          @errors << "第#{index + 1}行,合同内容不符合规范(用工性质、变更标致、开始时间、结束时间 均不能为空)"
          next
        end

        if Contract.where(
            start_date:  Date.parse(row[10].to_s),
            end_date:    row[11].to_s != "无固定" ? Date.parse(row[11].to_s) : nil,
            apply_type:  row[7],
            employee_id: @employee.id
        ).present?
          @errors << "第#{index + 1}行, 合同数据重复"
          next
        end
      end
    end

    def import_contract
      Contract.transaction do
        @sheet.each_with_index do |row, index|
          next if index == 0
          @employee = Employee.unscoped.where(employee_no: row[0], name: row[6]).first

          next unless @employee.present?

          if row[10].blank? || row[8].blank? || row[7].blank? || row[11].blank?
            next
          end

          @contract = @employee.contracts.create(
            employee_name:   @employee.name,
            employee_no:     @employee.employee_no,
            department_name: @employee.department.full_name,
            position_name:   EmployeePosition.full_position_name(@employee.employee_positions),
            contract_no:     @employee.employee_no,
            employee_exists: true,
            apply_type:  row[7],
            change_flag: row[8],
            start_date:  Date.parse(row[10].to_s),
            end_date: row[11].to_s != "无固定" ? Date.parse(row[11].to_s) : nil,
            due_time: row[11].to_s != "无固定" ? "#{(Date.parse(row[11].to_s) - Date.parse(row[10].to_s)).to_i/365}年#{(Date.parse(row[11].to_s) - Date.parse(row[10].to_s)).to_i%365}天" : row[11].to_s,
            is_unfix: row[11].to_s == "无固定" ? true : false,
          )

          @contract.judge_merge_contract
          if((@contract.apply_type == '合同' or @contract.apply_type == '合同制') and (@contract.change_flag == '转制' or @contract.change_flag == '新签'))
            category = @contract.change_flag == '转制' ? '合同转制' : '合同新签'
            hash = {employee_id: @employee.id, category: category, date: @contract.start_date}
            Publisher.broadcast_event('SOCIAL_CHANGE_INFO', hash)
          end
          if(%w(合同 合同制 公务员).include?(@contract.apply_type) and @contract.change_flag == '新签')
            hash = {employee_id: @employee.id, category: '合同新签', date: @contract.start_date, prev_channel_id: @employee.channel_id_was}
            Publisher.broadcast_event('SALARY_CHANGE', hash)
          end
          @employee.change_info_by_contract(@contract) if @contract.change_flag == "转制"
          Notification.send_user_message(@employee.id, "general", "你可于下月开始，加入川航企业年金，请在员工自助，我的申请中点击企业年金，进行了解和申请。") if @contract.apply_type == "合同制" && @contract.change_flag == "转制"
        end
      end
    end
  end
end
