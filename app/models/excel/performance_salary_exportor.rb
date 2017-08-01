require 'spreadsheet'
require 'zip'

module Excel
  class PerformanceSalaryExportor
    CATEGORY = ['合同工', '合同制', '重庆合同工', '重庆合同制']

    class << self
      def export_base_salary(salaries, month, department_id)
        book = Spreadsheet.open("#{Rails.root}/public/template/performance_salary.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1
        ganbu, yuangong = 0, 0

        index = 0
        salaries.each do |salary|
          next if salary.employee.full_month_vacation?(month)

          full_name = salary.employee.department.full_name.split("-")
          sheet1[index + 1, 0] = salary.employee.employee_no
          sheet1[index + 1, 1] = full_name[0]
          sheet1[index + 1, 2] = full_name[1]
          sheet1[index + 1, 3] = full_name[2]
          sheet1[index + 1, 4] = salary.employee.duty_rank.try(:display_name)
          sheet1[index + 1, 5] = salary.employee.name
          sheet1[index + 1, 7] = salary.base_salary
          if %w(领导 干部).include?(salary.employee.category.try(:display_name))
            ganbu = ganbu + salary.base_salary
          else
            yuangong = yuangong + salary.base_salary
          end

          index += 1
        end

        department = Department.find_by(id: department_id)
        department_salary = department.department_salaries.find_or_create_by(month: month)
        prev_department_salary = department.department_salaries.find_by(month: (month + '-01').to_date.prev_month.strftime("%Y-%m"))
        department_salary.update(verify_limit: ((ganbu + yuangong)*1.05).round(2), 
          leader_verify_limit: (ganbu*1.05).round(2),
          employee_verify_limit: (yuangong*1.05).round(2))
        sheet0[3, 0] = department.name
        sheet0[3, 1] = month
        sheet0[3, 2] = department_salary.verify_limit
        sheet0[3, 5] = prev_department_salary.try(:remain)
        sheet0[3, 10] = department_salary.leader_verify_limit
        sheet0[3, 13] = prev_department_salary.try(:leader_remain)
        sheet0[3, 17] = department_salary.employee_verify_limit
        sheet0[3, 20] = prev_department_salary.try(:employee_remain)

        sheet1.name = department.name
        filename = month + "绩效基数.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_nc(records, month)
        book1 = book2 = book3 = book4 = nil
        sheet1 = sheet2 = sheet3 = sheet4 = nil
        data1 = data2 = data3 = data4 = nil
        format_cell = Spreadsheet::Format.new :weight => :bold,
                                              :size => 14,
                                              :align => :center
        folder = "#{Rails.root}/public/export/tmp/performance-salaries/"
        FileUtils.mkdir_p(folder + month) unless File.directory?(folder + month)
        input_filenames = []

        (1..4).each do |key|
          eval("book#{key} = Spreadsheet::Workbook.new")
          eval("sheet#{key} = book#{key}.create_worksheet")
          eval("sheet#{key}.row(0).default_format = format_cell")
          eval("sheet#{key}.row(0).height = 28")
          eval("['', '人员编码', '考核性收入'].each_with_index{|v, i| sheet#{key}.column(i).width = 15;sheet#{key}.row(0).push(v)}")
          eval("data#{key} = records.select{|r| r.salary_set_book == CATEGORY[#{key - 1}] && r.total.to_f > 0}")
          eval("write_nc_xls(sheet#{key}, data#{key})")
          eval("book#{key}.write(folder + month + '/' + CATEGORY[#{key - 1}] + '.xls')")
          input_filenames << CATEGORY[key - 1] + '.xls'
        end

        zip_filename = "#{month}绩效薪酬NC表#{Time.now.to_s(:db)}.zip"
        creation_zip_file(folder, zip_filename, input_filenames, month)
        {
          path: folder + zip_filename,
          filename: zip_filename
        }
      end

      def export_approval(month)
        salaries = PerformanceSalary.joins(employee: [:department, :channel])
          .includes(employee: [:salary_person_setup, :duty_rank, :labor_relation, :channel, :performance_salaries])
          .order(
          "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
          ).where("performance_salaries.month = '#{month}' and employees.pcategory != '主官' and 
          departments.full_name not like '商旅公司%' and code_table_channels.display_name != '空勤' 
          and code_table_channels.display_name != '飞行'")

        book1 = Spreadsheet::Workbook.new
        sheet1 = sheet2 = sheet3 = nil
        format_cell = Spreadsheet::Format.new :weight => :bold,
                                              :size => 14,
                                              :align => :center
        (1..3).each do |x|
          eval("sheet#{x} = book1.create_worksheet")
          eval("sheet#{x}.row(0).default_format = format_cell")
          eval("sheet#{x}.row(0).height = 28")
        end

        book2 = Spreadsheet.open("#{Rails.root}/public/template/approval_perf_salary.xls")
        sheet4, sheet5, sheet6 = book2.worksheet(0), book2.worksheet(1), book2.worksheet(2)
        folder = "#{Rails.root}/public/export/tmp/performance-salaries/"

        FileUtils.mkdir_p(folder + month) unless File.directory?(folder + month)
        filename, input_filenames = nil, []

        gongsi = salaries.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        chongqing = salaries.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}

        # 地面绩效考核总表（打印表）sheet1
        ['人员编码', '部门', '姓名', '考核性收入', '帐套'].each_with_index do |v, i|
          sheet1.column(i).width = 15
          sheet1.row(0).push(v)
        end
        gongsi.each_with_index do |record, index|
          sheet1.row(index + 1).height = 16
          sheet1[index + 1, 0] = record.employee_no
          sheet1[index + 1, 1] = record.department_name.split("-").first
          sheet1[index + 1, 2] = record.employee_name
          sheet1[index + 1, 3] = format("%.2f", record.total)
          sheet1[index + 1, 4] = record.salary_set_book
        end

        ['部门', '考核性收入(元）', '备注'].each_with_index do |v, i|
          sheet2.column(i).width = sheet3.column(i).width = 18
          sheet2.row(0).push(v)
          sheet3.row(0).push(v)
        end

        sheet2_index = sheet3_index = 1
        # sheet2
        sheet2.name = '重庆'
        chongqing.group_by{|salary| salary.department_name.split("-").first}.each do |key, value|
          sheet2.row(sheet2_index).height = 16
          sheet2.column(0).default_format = format_cell
          sheet2[sheet2_index, 0] = "#{key}  汇总"
          sheet2[sheet2_index, 1] = format("%.2f", value.map(&:total).map(&:to_f).inject(&:+))
          sheet2_index += 1
        end
        # sheet3
        sheet3.name = '公司'
        gongsi.group_by{|salary| salary.department_name.split("-").first}.each do |key, value|
          sheet3.row(sheet3_index).height = 16
          sheet3.column(0).default_format = format_cell
          sheet3[sheet3_index, 0] = "#{key}  汇总"
          sheet3[sheet3_index, 1] = format("%.2f", value.map(&:total).map(&:to_f).inject(&:+))
          sheet3_index += 1
        end
        (2..3).each do |key|
          eval("sheet#{key}.row(sheet#{key}_index + 1).height = 16")
          eval("sheet#{key}[sheet#{key}_index + 1, 0] = '制表：'")
          eval("sheet#{key}[sheet#{key}_index + 1, 1] = '审核：'")
          eval("sheet#{key}[sheet#{key}_index + 1, 2] = '科室领导：'")
          eval("sheet#{key}[sheet#{key}_index + 3, 2] = '人力资源部'")
          eval("sheet#{key}[sheet#{key}_index + 4, 2] = Date.current.to_s")
        end

        prev_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")
        sheet4[0, 27] = "#{month.split('-').first}年#{month.split('-').last.to_i}月备注"
        sheet5[0, 12] = "#{month.split('-').first}年#{month.split('-').last.to_i}月备注"
        sheet6[0, 10] = "#{month.split('-').first}年#{month.split('-').last.to_i}月备注"

        salaries.each_with_index do |record, index|
          departments = record.department_name.split("-")
          prev_salary = record.employee.performance_salaries.select{|s| s.month == prev_month}.first

          write_approval_all(sheet4, record, index, departments, prev_salary)
          write_approval_obj(sheet6, record, index, departments, prev_salary)
        end

        book1.write(folder + month + "/#{month.gsub('-', '')}地面绩效考核总表(打印表).xls")
        book2.write(folder + month + "/#{month.gsub('-', '')}地面绩效考核总表(变动表).xls")
        input_filenames = ["#{month.gsub('-', '')}地面绩效考核总表(打印表).xls", "#{month.gsub('-', '')}地面绩效考核总表(变动表).xls"]

        zip_filename = "#{month}绩效薪酬审批表#{Time.now.to_s(:db)}.zip"
        creation_zip_file(folder, zip_filename, input_filenames, month)
        {
          path: folder + zip_filename,
          filename: zip_filename
        }
      end

      def write_nc_xls(sheet, records)
        records.each_with_index do |record, index|
          sheet[index + 1, 1] = record.employee_no
          sheet[index + 1, 2] = format("%.2f", record.total)
        end
      end

      def write_approval_all(sheet, record, index, departments, prev_salary)
        sheet.row(index + 1).height = 16
        sheet[index + 1, 0] = record.employee_no
        sheet[index + 1, 1] = departments[0]
        sheet[index + 1, 2] = departments[1]
        sheet[index + 1, 3] = departments[2]
        sheet[index + 1, 4] = record.employee.duty_rank.try(:display_name)
        sheet[index + 1, 5] = record.employee_name
        sheet[index + 1, 6] = record.employee.join_scal_date.to_s
        sheet[index + 1, 7] = record.employee.labor_relation.try(:display_name)
        sheet[index + 1, 8] = record.position_name
        sheet[index + 1, 11] = record.employee.channel.try(:display_name)
        sheet[index + 1, 12] = record.coefficient.to_f
        sheet[index + 1, 13] = prev_salary.try(:cardinal).to_f
        sheet[index + 1, 14] = record.cardinal.to_f
        sheet[index + 1, 15] = record.cardinal.to_f - prev_salary.try(:cardinal).to_f
        sheet[index + 1, 16] = record.cardinal.to_f
        sheet[index + 1, 17] = format("%.2f", record.summary_deduct.to_f)
        sheet[index + 1, 18] = format("%.2f", record.base_salary.to_f)
        sheet[index + 1, 19] = record.result
        sheet[index + 1, 20] = record.department_distribute.to_f
        sheet[index + 1, 21] = record.department_reserved.to_f
        sheet[index + 1, 22] = format("%.3f", record.performance_coeffic.to_f)
        sheet[index + 1, 23] = format("%.2f", record.amount.to_f)
        sheet[index + 1, 24] = record.refund_fee
        sheet[index + 1, 25] = record.add_garnishee
        sheet[index + 1, 26] = record.total
        sheet[index + 1, 27] = record.remark
        sheet[index + 1, 30] = record.summary_days
      end

      def write_approval_obj(sheet, record, index, departments, prev_salary)
        sheet.row(index + 1).height = 16
        sheet[index + 1, 1] = record.employee_no
        sheet[index + 1, 2] = departments[0]
        sheet[index + 1, 3] = record.employee_name
        sheet[index + 1, 4] = record.employee.channel.try(:display_name)
        sheet[index + 1, 5] = prev_salary.try(:cardinal).to_f
        sheet[index + 1, 6] = record.cardinal.to_f
        sheet[index + 1, 7] = record.cardinal.to_f - prev_salary.try(:cardinal).to_f
        sheet[index + 1, 8] = format("%.2f", record.summary_deduct.to_f)
        sheet[index + 1, 9] = record.add_garnishee
        sheet[index + 1, 10] = record.remark
        sheet[index + 1, 12] = record.summary_days
      end

      def creation_zip_file(folder, zip_filename, input_filenames, month)
        zipfile_name = folder + zip_filename

        Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
          input_filenames.each do |filename|
            zipfile.add(filename, folder + month + '/' + filename)
          end
        end
      end

    end
  end
end