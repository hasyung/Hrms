require 'spreadsheet'

module Excel
  class EarlyRetireEmployeeImportor

    def self.import(file_path)
      sheet = get_sheet(file_path)

      error_names, error_count = [], 0

      puts "开始导入退养人员花名册"

      EarlyRetireEmployee.transaction do
        sheet.each_with_index do |row, index|
          printf("*") if index % 100 == 0
          next if index == 0
          last_dep = nil
          first_dep = Department.find_by(name: row[1])

          secend_dep = first_dep.childrens.find_by(name: row[2]) if row[2]
          if secend_dep
            last_dep = row[3] ? secend_dep.childrens.find_by(name: row[3]) : secend_dep
          else
            last_dep = first_dep.childrens.find_by(name: row[3])
          end
          last_dep = first_dep if row[2].blank? && row[3].blank?
          position = last_dep.positions.find_by(name: row[12]) if last_dep

          if last_dep.blank? || position.blank?
            error_names << "#{row[6]} #{row[4]}"
            error_count += 1
          else
            employee = Employee.unscoped.find_by(name: row[4], employee_no: row[6]) || Employee.new
            hash = {
              name: row[4],
              employee_no: row[6],
              channel_id: CodeTable::Channel.find_by(display_name: row[9]).try(:id),
              category_id: CodeTable::Category.find_by(display_name: "员工").try(:id),
              labor_relation_id: Employee::LaborRelation.find_by(display_name: row[15]).try(:id),
              gender_id: CodeTable::Gender.find_by(display_name: row[17]).try(:id),
              nation: row[18],
              birthday: row[19],
              identity_no: row[20],
              education_background_id: CodeTable::EducationBackground.find_by(display_name: row[21]).try(:id),
              start_work_date: row[23],
              join_scal_date: row[24],
              political_status_id: CodeTable::PoliticalStatus.find_by(display_name: row[29]).try(:id),
              is_delete: true,
              leave_job_reason: '退养'
            }
            employee.assign_attributes(hash)
            if employee.save_without_auditing
              if employee.employee_positions.find_by(position_id: position.id).blank?
                employee_position = employee.employee_positions.new({
                  position_id: position.id,
                  end_date: Date.current
                })
                employee_position.save_without_auditing
              end

              if EarlyRetireEmployee.find_by(employee_id: employee.id).blank?
                EarlyRetireEmployee.create({
                  department: last_dep.full_name,
                  name: employee.name,
                  employee_no: employee.employee_no,
                  labor_relation: row[15],
                  change_date: Date.current,
                  position: position.name,
                  channel: row[9],
                  gender: row[17],
                  birthday: row[19],
                  identity_no: row[20],
                  join_scal_date: row[24],
                  employee_id: employee.id
                })
              end

              if row[32] && employee.education_experiences.find_by(school: row[32]).blank?
                experience = employee.education_experiences.new({
                  school: row[32],
                  major: row[33],
                  graduation_date: row[34],
                  education_background_id: CodeTable::EducationBackground.find_by(display_name: row[21]).try(:id)
                })
                experience.save_without_auditing
              end

              if row[39] && employee.contact.blank?
                contact = employee.build_contact({
                  address: row[39],
                  mailing_address: row[40],
                  mobile: row[40].to_s.length == 11 ? row[40] : nil,
                  telephone: row[40].to_s.length == 11 ? nil : row[40]
                })
                contact.save_without_auditing
              end
            end
          end
        end
      end

      if error_count > 0
        puts error_names.join("\r\n").red
        puts "提示: 总共处理 #{sheet.count - 1} 行数据".yellow
        puts "警告: 有 #{error_count} 行导入失败，失败率 #{error_count * 100/(sheet.count - 1)}% \r\n\r\n".red
      end
    end

    private
    def self.get_sheet(file_path)
      book = Spreadsheet.open(file_path)
      book.worksheet 0
    end

  end
end
