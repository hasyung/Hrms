require 'spreadsheet'

module Excel
  class EmployeeExportor

      COLUMNS = ['分公司', '一正部门', '一副部门', '二正部门', '姓名', '员工代码', '分类', '通道', '类别', '岗位',
      '岗位备注', '技术等级', '员工星级', '属地化地点', '用工性质', '职务职级', '性别', '国籍', '民族', '出生日期', '身份证号', '学历', '学位', '参工时间',
      '到岗时间', '实习时间', '职称', '职称级别','政治面貌', '转合同制时间', '转合同时间', '毕业院校', '专业', '毕业时间',
      '外语等级', '学历变更时间', '原学历', '户籍地址', '现住址', '手机号码']

    class << self
      def export(employees)

        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet

        sheet.row(0).default_format = Spreadsheet::Format.new :weight => :bold,
                                                              :size => 14,
                                                              :align => :center
        sheet.row(0).height = 25

        COLUMNS.each_with_index do |value, index|
          sheet.column(index).width = 15
          sheet.row(0).push(value)
        end

        index = 0
        employees.each do |employee|
          sheet.row(index + 1).height = 15
          departments = employee.department.parent_chain
          sheet[index + 1, 0] = departments.select{|d| d.grade.name == 'branch_company'}.map(&:name).join("-")
          sheet[index + 1, 1] = departments.select{|d| d.grade.name == 'positive' || d.grade.name == 'scal'}.map(&:name).join("-")
          sheet[index + 1, 2] = departments.select{|d| d.grade.name == 'deputy'}.map(&:name).join("-")
          sheet[index + 1, 3] = departments.select{|d| d.grade.name == 'secondly_positive'}.map(&:name).join("-")
          sheet[index + 1, 4] = employee.name
          sheet[index + 1, 5] = employee.employee_no
          sheet[index + 1, 6] = employee.category.try(:display_name) || employee.master_positions.first.category.try(:display_name)
          sheet[index + 1, 7] = employee.channel.try(:display_name) || employee.master_positions.first.channel.try(:display_name)
          sheet[index + 1, 8] = employee.classification
          sheet[index + 1, 9] = EmployeePosition.full_position_name(employee.employee_positions)
          sheet[index + 1, 10] = employee.position_remark

          sheet[index + 1, 11] = employee.try(:technical)
          sheet[index + 1, 12] = employee.star


          sheet[index + 1, 13] = employee.location
          sheet[index + 1, 14] = employee.labor_relation.try(:display_name)
          sheet[index + 1, 15] = employee.duty_rank.try(:display_name)
          sheet[index + 1, 16] = employee.gender.try(:display_name)
          sheet[index + 1, 17] = employee.nationality
          sheet[index + 1, 18] = employee.nation
          sheet[index + 1, 19] = employee.birthday.try(:to_s, :db)
          sheet[index + 1, 20] = employee.identity_no
          sheet[index + 1, 21] = employee.education_background.try(:display_name)
          sheet[index + 1, 22] = employee.degree.try(:display_name)
          sheet[index + 1, 23] = employee.start_work_date.try(:to_s, :db)
          sheet[index + 1, 24] = employee.join_scal_date.try(:to_s, :db)
          sheet[index + 1, 25] = employee.start_internship_date.try(:to_s, :db)
          sheet[index + 1, 26] = employee.job_title
          sheet[index + 1, 27] = employee.job_title_degree.try(:display_name)
          sheet[index + 1, 28] = employee.political_status.try(:display_name)
          sheet[index + 1, 29] = employee.change_contract_system_date.try(:to_s, :db)
          sheet[index + 1, 30] = employee.change_contract_date.try(:to_s, :db)
          sheet[index + 1, 31] = employee.school
          sheet[index + 1, 32] = employee.major
          sheet[index + 1, 33] = employee.graduate_date.try(:to_s, :db)
          sheet[index + 1, 34] = employee.language_names
          sheet[index + 1, 35] = employee.change_education_date.try(:to_s, :db)
          sheet[index + 1, 36] = employee.old_education_data[:education]
          sheet[index + 1, 37] = employee.native_place
          sheet[index + 1, 38] = employee.contact.try(:address)
          sheet[index + 1, 39] = employee.contact.try(:mobile)
          

          index += 1
        end

        filename = "#{Time.now.to_i}人员明细.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end
    end

  end
end
