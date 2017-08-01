require 'spreadsheet'
require 'zip'

module Excel
  class BasicSalaryExportor
    COLUMNS = [
      ['', '人员编码', '基本工资'],
      ['', '人员编码', '川航工龄'],
      ['', '人员编码', '保留'],
      ['', '人员编码', '补发'],
      ['', '人员编码', '扣发']
    ]
    CATEGORY = ['合同工', '合同制', '重庆合同工', '重庆合同制']
    SIMPLE_CATEGORY = ['工', '制', '重工', '重制']

    class << self
      def export_approval(records, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/basic_salary.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1
        sheet2 = book.worksheet 2

        prev_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")
        row_index_0 = row_index_1 = row_index_2 =  2
        sheet0[0, 15] = "#{month.split('-').first}年#{month.split('-').last.to_i}月备注"
        sheet1[0, 15] = "#{month.split('-').first}年#{month.split('-').last.to_i}月备注"
        sheet2[0, 15] = "#{month.split('-').first}年#{month.split('-').last.to_i}月备注"

        sheet0_1 = sheet0_2 = sheet0_3 = sheet0_4 = sheet0_5 = sheet0_6 = sheet0_7 = sheet0_8 = sheet0_9 = sheet0_10 = 0
        sheet1_1 = sheet1_2 = sheet1_3 = sheet1_4 = sheet1_5 = sheet1_6 = sheet1_7 = sheet1_8 = sheet1_9 = sheet1_10 = 0
        sheet2_1 = sheet2_2 = sheet2_3 = sheet2_4 = sheet2_5 = sheet2_6 = sheet2_7 = sheet2_8 = sheet2_9 = sheet2_10 = 0

        records.each do |record|
          prev_basic_salary = record.employee.basic_salaries.select{|s| s.month == prev_month}.first
          prev_keep_salary = record.employee.keep_salaries.select{|s| s.month == prev_month}.first
          current_keep_salary = record.employee.keep_salaries.select{|s| s.month == month}.first

          standard_change = record.standard.to_f - prev_basic_salary.try(:standard).to_f
          years_salary_change = record.working_years_salary.to_f - prev_basic_salary.try(:working_years_salary).to_f
          keep_salary_change = current_keep_salary.try(:total).to_f - prev_keep_salary.try(:total).to_f
          add_garnishee = record.add_garnishee.to_f

          next if standard_change == 0 && years_salary_change == 0 && keep_salary_change == 0 && record.deduct_money == 0 && add_garnishee == 0 

          sheet0.row(row_index_0).height = 16
          set_xls_value(sheet0, row_index_0, record, prev_basic_salary, prev_keep_salary, current_keep_salary, standard_change, years_salary_change, keep_salary_change)
          unless standard_change == 0
            sheet0_1 += prev_basic_salary.try(:standard).to_f
            sheet0_2 += record.standard.to_f
            sheet0_3 += standard_change
          end
          unless years_salary_change == 0
            sheet0_4 += prev_basic_salary.try(:working_years_salary).to_f
            sheet0_5 += record.working_years_salary.to_f
            sheet0_6 += years_salary_change
          end
          unless keep_salary_change == 0
            sheet0_7 += prev_keep_salary.try(:total).to_f
            sheet0_8 += current_keep_salary.try(:total).to_f
            sheet0_9 += keep_salary_change
          end
          
          sheet0_10 += record.deduct_money + add_garnishee if record.deduct_money != 0 || add_garnishee != 0
          row_index_0 += 1
          if %w(合同工 合同制).include?(record.salary_set_book)
            sheet1.row(row_index_1).height = 16
            set_xls_value(sheet1, row_index_1, record, prev_basic_salary, prev_keep_salary, current_keep_salary, standard_change, years_salary_change, keep_salary_change)
            unless standard_change == 0
              sheet1_1 += prev_basic_salary.try(:standard).to_f
              sheet1_2 += record.standard.to_f
              sheet1_3 += standard_change
            end
            unless years_salary_change == 0
              sheet1_4 += prev_basic_salary.try(:working_years_salary).to_f
              sheet1_5 += record.working_years_salary.to_f
              sheet1_6 += years_salary_change
            end
            unless keep_salary_change == 0
              sheet1_7 += prev_keep_salary.try(:total).to_f
              sheet1_8 += current_keep_salary.try(:total).to_f
              sheet1_9 += keep_salary_change
            end
            sheet1_10 += record.deduct_money + add_garnishee if record.deduct_money != 0 || add_garnishee != 0
            row_index_1 += 1
          end
          if %w(重庆合同工 重庆合同制).include?(record.salary_set_book)
            sheet2.row(row_index_2).height = 16
            set_xls_value(sheet2, row_index_2, record, prev_basic_salary, prev_keep_salary, current_keep_salary, standard_change, years_salary_change, keep_salary_change)
            unless standard_change == 0
              sheet2_1 += prev_basic_salary.try(:standard).to_f
              sheet2_2 += record.standard.to_f
              sheet2_3 += standard_change
            end
            unless years_salary_change == 0
              sheet2_4 += prev_basic_salary.try(:working_years_salary).to_f
              sheet2_5 += record.working_years_salary.to_f
              sheet2_6 += years_salary_change
            end
            unless keep_salary_change == 0
              sheet2_7 += prev_keep_salary.try(:total).to_f
              sheet2_8 += current_keep_salary.try(:total).to_f
              sheet2_9 += keep_salary_change
            end
            sheet2_10 += record.deduct_money + add_garnishee if record.deduct_money != 0 || add_garnishee != 0
            row_index_2 += 1
          end
        end
        sheet0.merge_cells row_index_0, 1, row_index_0, 4
        sheet0[row_index_0, 1] = '合计'
        (0..2).each do |x|
          (1..10).each do |y|
            eval("sheet#{x}[row_index_#{x}, #{y} + 4] = format('%.2f', sheet#{x}_#{y})")
          end
        end

        keep_salaries = KeepSalary.where(month: month)

        zhigong = records.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        sheet1[row_index_1 + 1, 5] = zhigong.map(&:standard).map(&:to_f).inject(&:+)
        sheet1[row_index_1 + 1, 8] = zhigong.map(&:working_years_salary).map(&:to_f).inject(&:+)
        sheet1[row_index_1 + 1, 11] = keep_salaries.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}.map(&:total).map(&:to_f).inject(&:+)
        sheet1[row_index_1 + 1, 14] = zhigong.map(&:deduct_money).map(&:to_f).inject(&:+) + zhigong.map(&:add_garnishee).map(&:to_f).inject(&:+)

        chongzhigong = records.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}
        sheet2[row_index_2 + 1, 5] = chongzhigong.map(&:standard).map(&:to_f).inject(&:+)
        sheet2[row_index_2 + 1, 8] = chongzhigong.map(&:working_years_salary).map(&:to_f).inject(&:+)
        sheet2[row_index_2 + 1, 11] = keep_salaries.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}.map(&:total).map(&:to_f).inject(&:+)
        sheet2[row_index_2 + 1, 14] = chongzhigong.map(&:deduct_money).map(&:to_f).inject(&:+) + chongzhigong.map(&:add_garnishee).map(&:to_f).inject(&:+)

        merge_cells(sheet1, row_index_1)
        merge_cells(sheet2, row_index_2)


        filename = "#{month.split('-').first}年#{month.split('-').last.to_i}月基础工资项目变动表.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_nc(records, month)
        book1 = book2 = book3 = book4 = book5 = book6 = book7 = book8 = book9 = book10 = nil
        book11 = book12 = book13 = book14 = book15 = book16 = book17 = book18 = book19 = book20 = nil
        sheet1 = sheet2 = sheet3 = sheet4 = sheet5 = sheet6 = sheet7 = sheet8 = sheet9 = sheet10 = nil
        sheet11 = sheet12 = sheet13 = sheet14 = sheet15 = sheet16 = sheet17 = sheet18 = sheet19 = sheet20 = nil
        index_1 = index_2 = index_3 = index_4 = index_5 = index_6 = index_7 = index_8 = index_9 = index_10 = 1
        index_11 = index_12 = index_13 = index_14 = index_15 = index_16 = index_17 = index_18 = index_19 = index_20 = 1

        format_cell = Spreadsheet::Format.new :weight => :bold,
                                              :size => 14,
                                              :align => :center

        index = 1
        (0..3).each do |x|
          (0..4).each do |key|
            eval("book#{index} = Spreadsheet::Workbook.new")
            eval("sheet#{index} = book#{index}.create_worksheet")
            eval("sheet#{index}.row(0).default_format = format_cell")
            eval("sheet#{index}.row(0).height = 28")
            eval("COLUMNS[#{key}].each_with_index{|v, i| sheet#{index}.column(i).width = 15;sheet#{index}.row(0).push(v)}")
            index += 1
          end
        end
        prev_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")

        records.each do |record|
          prev_basic_salary = record.employee.basic_salaries.select{|s| s.month == prev_month}.first
          prev_keep_salary = record.employee.keep_salaries.select{|s| s.month == prev_month}.first
          current_keep_salary = record.employee.keep_salaries.select{|s| s.month == month}.first

          standard_change = record.standard.to_f - prev_basic_salary.try(:standard).to_f
          years_salary_change = record.working_years_salary.to_f - prev_basic_salary.try(:working_years_salary).to_f
          keep_salary_change = current_keep_salary.try(:total).to_f - prev_keep_salary.try(:total).to_f

          next if standard_change == 0 && years_salary_change == 0 && keep_salary_change == 0 && record.deduct_money == 0 && record.add_garnishee.to_f == 0

          category_index = CATEGORY.index(record.salary_set_book)
          next if category_index.blank?
          source = nil

          unless standard_change == 0
            eval("source = sheet#{category_index * 5 + 1}")
            eval("index = index_#{category_index * 5 + 1}")
            source.row(index).height = 16
            source[index, 1] = record.employee_no
            source[index, 2] = format("%.2f", record.standard.to_f)
            eval("index_#{category_index * 5 + 1} += 1")
          end
          unless years_salary_change == 0
            eval("source = sheet#{category_index * 5 + 2}")
            eval("index = index_#{category_index * 5 + 2}")
            source.row(index).height = 16
            source[index, 1] = record.employee_no
            source[index, 2] = format("%.2f", record.working_years_salary.to_f)
            eval("index_#{category_index * 5 + 2} += 1")
          end
          unless keep_salary_change == 0
            eval("source = sheet#{category_index * 5 + 3}")
            eval("index = index_#{category_index * 5 + 3}")
            source.row(index).height = 16
            source[index, 1] = record.employee_no
            source[index, 2] = format("%.2f", current_keep_salary.try(:total).to_f)
            eval("index_#{category_index * 5 + 3} += 1")
          end
          if record.add_garnishee.to_f > 0
            eval("source = sheet#{category_index * 5 + 4}")
            eval("index = index_#{category_index * 5 + 4}")
            source.row(index).height = 16
            source[index, 1] = record.employee_no
            source[index, 2] = format("%.2f", record.add_garnishee.to_f)
            eval("index_#{category_index * 5 + 4} += 1")
          end
          if record.deduct_money < 0 || record.add_garnishee.to_f < 0
            money = record.add_garnishee.to_f < 0 ? record.deduct_money + record.add_garnishee.to_f : record.deduct_money
            eval("source = sheet#{category_index * 5 + 5}")
            eval("index = index_#{category_index * 5 + 5}")
            source.row(index).height = 16
            source[index, 1] = record.employee_no
            source[index, 2] = format("%.2f", money)
            eval("index_#{category_index * 5 + 5} += 1")
          end
        end

        folder = "#{Rails.root}/public/export/tmp/basic-salaries/"
        FileUtils.mkdir_p(folder + month) unless File.directory?(folder + month)
        filename, input_filenames = nil, []
        (0..3).each do |x|
          (0..4).each do |key|
            eval("filename = '#{SIMPLE_CATEGORY[x]}-#{COLUMNS[key][2]}'")
            eval("book#{x * 5 + key + 1}.write(folder + month + '/' + filename + '.xls')")
            input_filenames << filename + '.xls'
          end
        end

        zip_filename = "#{month}基础薪酬NC表#{Time.now.to_s(:db)}.zip"
        creation_zip_file(folder, zip_filename, input_filenames, month)
        {
          path: folder + zip_filename,
          filename: zip_filename
        }
      end

      def set_xls_value(sheet, row_index, record, prev_basic, prev_keep, current_keep, a, b, c)
        sheet[row_index, 1] = record.employee_no
        sheet[row_index, 2] = record.department_name.split("-").first
        sheet[row_index, 3] = record.employee_name
        sheet[row_index, 4] = record.salary_set_book
        unless a == 0
          sheet[row_index, 5] = format("%.2f", prev_basic.try(:standard).to_f)
          sheet[row_index, 6] = format("%.2f", record.standard.to_f)
          sheet[row_index, 7] = format("%.2f", a)
        end
        unless b == 0
          sheet[row_index, 8] = format("%.2f", prev_basic.try(:working_years_salary).to_f)
          sheet[row_index, 9] = format("%.2f", record.working_years_salary.to_f)
          sheet[row_index, 10] = format("%.2f", b)
        end
        unless c == 0
          sheet[row_index, 11] = format("%.2f", prev_keep.try(:total).to_f)
          sheet[row_index, 12] = format("%.2f", current_keep.try(:total).to_f)
          sheet[row_index, 13] = format("%.2f", c)
        end
        sheet[row_index, 14] = format("%.2f", record.deduct_money + record.add_garnishee.to_f) if record.deduct_money != 0 || record.add_garnishee.to_f != 0
        sheet[row_index, 15] = record.notes.to_s + record.remark.to_s
      end

      def merge_cells(sheet, row_index)
        sheet.merge_cells row_index, 1, row_index, 4
        sheet.merge_cells row_index + 1, 1, row_index + 1, 4
        sheet.merge_cells row_index + 1, 5, row_index + 1, 7
        sheet.merge_cells row_index + 1, 8, row_index + 1, 10
        sheet.merge_cells row_index + 1, 11, row_index + 1, 13
        sheet.merge_cells row_index + 2, 15, row_index + 2, 16
        sheet.merge_cells row_index + 3, 15, row_index + 3, 16
        sheet[row_index, 1] = '合计'
        sheet[row_index + 1, 1] = '本月实际发放数'
        sheet[row_index + 2, 5] = '制表：'
        sheet[row_index + 2, 13] = '审核：'
        sheet[row_index + 2, 15] = '人力资源部'
        sheet[row_index + 3, 5] = '科室领导：'
        sheet[row_index + 3, 15] = Date.current.to_s
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