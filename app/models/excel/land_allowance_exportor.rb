module Excel
  class LandAllowanceExportor
    CATEGORY = ['合同工', '合同制', '重庆合同工', '重庆合同制']

  	class << self
      def export_approval(records, month)
      	book = Spreadsheet.open("#{Rails.root}/public/template/land_allowance.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1
        sheet2 = book.worksheet 2

        gongsi = records.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        chongqing = records.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}
        dep_hash = Department.includes(:grade).index_by(&:name)

        records.each_with_index do |record, index|
          sheet0.row(index + 1).height = 15

          record.department_name.split("-").each do |dep_name|
            grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
            if %w(分公司 一正级).include?(grade_name)
              sheet0[index + 1, 1] = dep_name
            elsif grade_name == '一副级'
              sheet0[index + 1, 2] = dep_name
            else
              sheet0[index + 1, 2] ||= dep_name
            end
          end

          sheet0[index + 1, 0] = record.employee_no
          sheet0[index + 1, 3] = record.position_name
          sheet0[index + 1, 4] = record.employee_name
          sheet0[index + 1, 5] = record.standard
          sheet0[index + 1, 6] = record.days
          sheet0[index + 1, 7] = record.subsidy.to_f
          sheet0[index + 1, 8] = record.add_garnishee.to_f if record.add_garnishee.to_f > 0
          sheet0[index + 1, 9] = record.add_garnishee.to_f.abs if record.add_garnishee.to_f < 0
          sheet0[index + 1, 10] = record.subsidy.to_f + record.add_garnishee.to_f
          sheet0[index + 1, 12] = record.notes
          sheet0[index + 1, 13] = record.locations
          sheet0[index + 1, 14] = record.salary_set_book
        end

        sheet_index = 1
        gongsi.group_by{|record| record.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            salary.department_name.split("-").each do |dep_name|
              grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
              if %w(分公司 一正级).include?(grade_name)
                sheet1[sheet_index, 1] = dep_name
              elsif grade_name == '一副级'
                sheet1[sheet_index, 2] = dep_name
              else
                sheet1[sheet_index, 2] ||= dep_name
              end
            end

            sheet1[sheet_index, 0] = salary.employee_no
            sheet1[sheet_index, 3] = salary.position_name
            sheet1[sheet_index, 4] = salary.employee_name
            sheet1[sheet_index, 5] = salary.standard
            sheet1[sheet_index, 6] = salary.days
            sheet1[sheet_index, 7] = salary.subsidy.to_f
            sheet1[sheet_index, 8] = salary.add_garnishee.to_f if salary.add_garnishee.to_f > 0
            sheet1[sheet_index, 9] = salary.add_garnishee.to_f.abs if salary.add_garnishee.to_f < 0
            sheet1[sheet_index, 10] = salary.subsidy.to_f + salary.add_garnishee.to_f
            
            sheet_index += 1
          end

          sheet1.row(sheet_index).height = 15

          sheet1[sheet_index, 1] = "#{key}  汇总"
          sheet1[sheet_index, 7] = format("%.2f", value.map(&:subsidy).map(&:to_f).inject(&:+))
          sheet1[sheet_index, 10] = format("%.2f", value.map(&:subsidy).map(&:to_f).inject(&:+) + 
          	value.map(&:add_garnishee).map(&:to_f).inject(&:+))
          sheet_index += 1
        end

        sheet_index = 1
        chongqing.group_by{|record| record.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            salary.department_name.split("-").each do |dep_name|
              grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
              if %w(分公司 一正级).include?(grade_name)
                sheet2[sheet_index, 1] = dep_name
              elsif grade_name == '一副级'
                sheet2[sheet_index, 2] = dep_name
              else
                sheet2[sheet_index, 2] ||= dep_name
              end
            end

            sheet2[sheet_index, 0] = salary.employee_no
            sheet2[sheet_index, 3] = salary.position_name
            sheet2[sheet_index, 4] = salary.employee_name
            sheet2[sheet_index, 5] = salary.standard
            sheet2[sheet_index, 6] = salary.days
            sheet2[sheet_index, 7] = salary.subsidy.to_f
            sheet2[sheet_index, 8] = salary.add_garnishee.to_f if salary.add_garnishee.to_f > 0
            sheet2[sheet_index, 9] = salary.add_garnishee.to_f.abs if salary.add_garnishee.to_f < 0
            sheet2[sheet_index, 10] = salary.subsidy.to_f + salary.add_garnishee.to_f
            
            sheet_index += 1
          end

          sheet2.row(sheet_index).height = 15

          sheet2[sheet_index, 1] = "#{key}  汇总"
          sheet2[sheet_index, 7] = format("%.2f", value.map(&:subsidy).map(&:to_f).inject(&:+))
          sheet2[sheet_index, 10] = format("%.2f", value.map(&:subsidy).map(&:to_f).inject(&:+) + 
          	value.map(&:add_garnishee).map(&:to_f).inject(&:+))
        end

        filename = "#{month}驻站津贴.xls"
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
        folder = "#{Rails.root}/public/export/tmp/land_allowances/"
        FileUtils.mkdir_p(folder + month) unless File.directory?(folder + month)
        input_filenames = []
        records = records.select{|r| r.subsidy.to_f > 0}

        (1..4).each do |key|
          eval("book#{key} = Spreadsheet::Workbook.new")
          eval("sheet#{key} = book#{key}.create_worksheet")
          eval("sheet#{key}.row(0).default_format = format_cell")
          eval("sheet#{key}.row(0).height = 28")
          eval("['', '人员编码', '驻站补贴'].each_with_index{|v, i| sheet#{key}.column(i).width = 15; 
            sheet#{key}.row(0).push(v)}")
          eval("data#{key} = records.select{|r| r.salary_set_book == CATEGORY[#{key - 1}]}")
          eval("write_nc_xls(sheet#{key}, data#{key})")
          eval("book#{key}.write(folder + month + '/' + CATEGORY[#{key - 1}] + '.xls')")
          input_filenames << CATEGORY[key - 1] + '.xls'
        end

        zip_filename = "#{month}驻站津贴NC表#{Time.now.to_s(:db)}.zip"
        creation_zip_file(folder, zip_filename, input_filenames, month)
        {
          path: folder + zip_filename,
          filename: zip_filename
        }
      end

      private
      def write_nc_xls(sheet, records)
        records.each_with_index do |record, index|
          sheet[index + 1, 1] = record.employee_no
          sheet[index + 1, 2] = format("%.2f", record.subsidy.to_f)
        end
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