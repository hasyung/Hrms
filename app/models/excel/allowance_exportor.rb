module Excel
  class AllowanceExportor
    CATEGORY = ['合同工', '合同制', '重庆合同工', '重庆合同制', '重庆合同工', '重庆合同制']
    OTHER_CATEGORY = ['合同工', '合同制', 
      '重庆合同工', '重庆合同制', 
      '重庆合同工免税', '重庆合同制免税']

    NC_CATEGORY = {
      'security_check' => '安检津贴',
      'resettlement' => '安置补贴',
      'group_leader,air_station_manage,cq_part_time_fix_car_subsidy,fly_honor' => '津贴',
      'car_present' => '车勤补贴',
      'land_present' => '地勤补贴',
      'permit_entry,part_permit_entry,try_drive' => '机务放行',
      'follow_plane,airline_practice' => '随机补贴',
      'permit_sign' => '签派放行',
      'work_overtime,watch_subsidy' => '值班工资',
      'logistical_support_subsidy' => '职务津贴'
    }
    GENEL_CATEGORY = ['合同工', '合同制', '重庆合同工', '重庆合同制']

    class << self
      def export_nc(records, month)
        book1 = book2 = book3 = book4 = book5 = book6 = book7 = book8 = book9 = book10 = nil
        book11 = book12 = book13 = book14 = book15 = book16 = book17 = book18 = book19 = book20 = nil
        book21 = book22 = book23 = book24 = book25 = book26 = book27 = book28 = book29 = book30 = nil
        book31 = book32 = book33 = book34 = book35 = book36 = book37 = book38 = book39 = book40 = nil
        sheet1 = sheet2 = sheet3 = sheet4 = sheet5 = sheet6 = sheet7 = sheet8 = sheet9 = sheet10 = nil
        sheet11 = sheet12 = sheet13 = sheet14 = sheet15 = sheet16 = sheet17 = sheet18 = sheet19 = sheet20 = nil
        sheet21 = sheet22 = sheet23 = sheet24 = sheet25 = sheet26 = sheet27 = sheet28 = sheet29 = sheet30 = nil
        sheet31 = sheet32 = sheet33 = sheet34 = sheet35 = sheet36 = sheet37 = sheet38 = sheet39 = sheet40 = nil
        data1 = data2 = data3 = data4 = data5 = data6 = data7 = data8 = data9 = data10 = nil
        data11 = data12 = data13 = data14 = data15 = data16 = data17 = data18 = data19 = data20 = nil
        data21 = data22 = data23 = data24 = data25 = data26 = data27 = data28 = data29 = data30 = nil
        data31 = data32 = data33 = data34 = data35 = data36 = data37 = data38 = data39 = data40 = nil
        format_cell = Spreadsheet::Format.new :weight => :bold,
                                              :size => 14,
                                              :align => :center
        folder = "#{Rails.root}/public/export/tmp/allowances/"
        FileUtils.mkdir_p(folder + month) unless File.directory?(folder + month)
        input_filenames = []

        (1..10).each do |key|
          (1..4).each do |ke|
            eval("book#{key*ke} = Spreadsheet::Workbook.new")
            eval("sheet#{key*ke} = book#{key*ke}.create_worksheet")
            eval("sheet#{key*ke}.row(0).default_format = format_cell")
            eval("sheet#{key*ke}.row(0).height = 28")
            eval("['', '人员编码'].each_with_index{|v, i| sheet#{key*ke}.column(i).width = 15; 
              sheet#{key*ke}.row(0).push(v)}")
            eval("sheet#{key*ke}.column(2).width = 15; sheet#{key*ke}.row(0).push(NC_CATEGORY.values[#{key - 1}])")

            eval("data#{key*ke} = records.select{|r| r.salary_set_book == GENEL_CATEGORY[#{ke - 1}] && 
              NC_CATEGORY.keys[#{key - 1}].split(',').inject([]){|arr, column| arr << r.send(column).to_f}.inject(&:+).to_f > 0}")
            eval("write_nc_xls(sheet#{key*ke}, data#{key*ke}, NC_CATEGORY.keys[#{key - 1}].split(','))")
            eval("book#{key*ke}.write(folder + month + '/' + NC_CATEGORY.values[#{key - 1}] + GENEL_CATEGORY[#{ke - 1}] + '.xls')")
            input_filenames << NC_CATEGORY.values[key - 1] + GENEL_CATEGORY[ke - 1] + '.xls'
          end
        end

        zip_filename = "#{month}津贴NC表#{Time.now.to_s(:db)}.zip"
        creation_zip_file(folder, zip_filename, input_filenames, month)
        {
          path: folder + zip_filename,
          filename: zip_filename
        }

      end


      def export_communication_nc(records, month)
        book1 = book2 = book3 = book4 = book5 = book6 = nil
        sheet1 = sheet2 = sheet3 = sheet4 = sheet5 = sheet6 = nil
        data1 = data2 = data3 = data4 = data5 = data6 = nil
        format_cell = Spreadsheet::Format.new :weight => :bold,
                                              :size => 14,
                                              :align => :center
        folder = "#{Rails.root}/public/export/tmp/allowances/"
        FileUtils.mkdir_p(folder + month) unless File.directory?(folder + month)
        input_filenames = []
        records = records.select{|r| r.communication.to_f > 0}

        (1..6).each do |key|
          eval("book#{key} = Spreadsheet::Workbook.new")
          eval("sheet#{key} = book#{key}.create_worksheet")
          eval("sheet#{key}.row(0).default_format = format_cell")
          eval("sheet#{key}.row(0).height = 28")
          eval("['', '人员编码', '通讯补贴'].each_with_index{|v, i| sheet#{key}.column(i).width = 15; 
            sheet#{key}.row(0).push(v)}")
          eval("data#{key} = records.select{|r| r.salary_set_book == CATEGORY[#{key - 1}]}")
          eval("special_type = 1; special_type = 2 if key == 3 or key == 4; special_type = 3 if key == 5 or key == 6; 
            write_communication_nc_xls(sheet#{key}, data#{key}, special_type)")
          eval("book#{key}.write(folder + month + '/' + OTHER_CATEGORY[#{key - 1}] + '.xls')")
          input_filenames << OTHER_CATEGORY[key - 1] + '.xls'
        end

        zip_filename = "#{month}通讯补贴NC表#{Time.now.to_s(:db)}.zip"
        creation_zip_file(folder, zip_filename, input_filenames, month)
        {
          path: folder + zip_filename,
          filename: zip_filename
        }
      end

      def export_land_present(allowances, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/land_present.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1
        sheet2 = book.worksheet 2

        allowances = allowances.select{|r| r.land_present.to_f > 0}

        gongsi = allowances.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        chongqing = allowances.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}
        dep_hash = Department.includes(:grade).index_by(&:name)

        allowances.each_with_index do |allowance, index|
          sheet0.row(index + 1).height = 15

          allowance.department_name.split("-").each do |dep_name|
            grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
            if %w(分公司 一正级).include?(grade_name)
              sheet0[index + 1, 0] = dep_name
            elsif grade_name == '一副级'
              sheet0[index + 1, 1] = dep_name
            else
              sheet0[index + 1, 2] = dep_name
            end
          end

          sheet0[index + 1, 3] = allowance.position_name
          sheet0[index + 1, 4] = allowance.employee_name
          sheet0[index + 1, 5] = allowance.employee_no
          sheet0[index + 1, 6] = allowance.employee.channel.try(:display_name)
          sheet0[index + 1, 7] = allowance.employee.labor_relation.try(:display_name)
          sheet0[index + 1, 8] = allowance.land_present_standard.to_f
          sheet0[index + 1, 9] = allowance.notes
          sheet0[index + 1, 12] = allowance.land_present.to_f
          sheet0[index + 1, 15] = allowance.salary_set_book
        end

        sheet_index = 1
        gongsi.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            salary.department_name.split("-").each do |dep_name|
              grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
              if %w(分公司 一正级).include?(grade_name)
                sheet1[sheet_index, 0] = dep_name
              elsif grade_name == '一副级'
                sheet1[sheet_index, 1] = dep_name
              else
                sheet1[sheet_index, 2] = dep_name
              end
            end

            sheet1[sheet_index, 3] = salary.position_name
            sheet1[sheet_index, 4] = salary.employee_name
            sheet1[sheet_index, 5] = salary.employee_no
            sheet1[sheet_index, 6] = salary.employee.channel.try(:display_name)
            sheet1[sheet_index, 7] = salary.employee.labor_relation.try(:display_name)
            sheet1[sheet_index, 8] = salary.land_present_standard.to_f
            sheet1[sheet_index, 12] = salary.land_present.to_f
            
            sheet_index += 1
          end

          sheet1.row(sheet_index).height = 15

          sheet1[sheet_index, 0] = "#{key}  汇总"
          sheet1[sheet_index, 8] = format("%.2f", value.map(&:land_present_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 12] = format("%.2f", value.map(&:land_present).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        sheet_index = 1
        chongqing.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            salary.department_name.split("-").each do |dep_name|
              grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
              if %w(分公司 一正级).include?(grade_name)
                sheet2[sheet_index, 0] = dep_name
              elsif grade_name == '一副级'
                sheet2[sheet_index, 1] = dep_name
              else
                sheet2[sheet_index, 2] = dep_name
              end
            end

            sheet2[sheet_index, 3] = salary.position_name
            sheet2[sheet_index, 4] = salary.employee_name
            sheet2[sheet_index, 5] = salary.employee_no
            sheet2[sheet_index, 6] = salary.employee.channel.try(:display_name)
            sheet2[sheet_index, 7] = salary.employee.labor_relation.try(:display_name)
            sheet2[sheet_index, 8] = salary.land_present_standard.to_f
            sheet2[sheet_index, 12] = salary.land_present.to_f
            
            sheet_index += 1
          end

          sheet2.row(sheet_index).height = 15

          sheet2[sheet_index, 0] = "#{key}  汇总"
          sheet2[sheet_index, 8] = format("%.2f", value.map(&:land_present_standard).map(&:to_f).inject(&:+).to_f)
          sheet2[sheet_index, 12] = format("%.2f", value.map(&:land_present).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        filename = "#{month}地勤津贴.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_car_present(allowances, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/car_present.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1
        sheet2 = book.worksheet 2

        allowances = allowances.select{|r| r.car_present.to_f > 0}

        gongsi = allowances.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        chongqing = allowances.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}

        allowances.each_with_index do |allowance, index|
          sheet0.row(index + 1).height = 15

          sheet0[index + 1, 0] = allowance.department_name.split("-").first
          sheet0[index + 1, 1] = allowance.employee_no
          sheet0[index + 1, 2] = allowance.employee_name
          sheet0[index + 1, 3] = allowance.position_name
          sheet0[index + 1, 4] = allowance.car_present_standard.to_f
          sheet0[index + 1, 7] = allowance.car_present.to_f
          sheet0[index + 1, 8] = allowance.notes
          sheet0[index + 1, 11] = allowance.salary_set_book
        end

        sheet_index = 1
        gongsi.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            sheet1[sheet_index, 0] = key
            sheet1[sheet_index, 1] = salary.employee_no
            sheet1[sheet_index, 2] = salary.employee_name
            sheet1[sheet_index, 3] = salary.position_name
            sheet1[sheet_index, 4] = salary.car_present_standard.to_f
            sheet1[sheet_index, 7] = salary.car_present.to_f
            
            sheet_index += 1
          end

          sheet1.row(sheet_index).height = 15

          sheet1[sheet_index, 0] = "#{key}  汇总"
          sheet1[sheet_index, 4] = format("%.2f", value.map(&:car_present_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 7] = format("%.2f", value.map(&:car_present).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        sheet_index = 1
        chongqing.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            sheet2[sheet_index, 0] = key
            sheet2[sheet_index, 1] = salary.employee_no
            sheet2[sheet_index, 2] = salary.employee_name
            sheet2[sheet_index, 3] = salary.position_name
            sheet2[sheet_index, 4] = salary.car_present_standard.to_f
            sheet2[sheet_index, 7] = salary.car_present.to_f
            
            sheet_index += 1
          end

          sheet2.row(sheet_index).height = 15

          sheet2[sheet_index, 0] = "#{key}  汇总"
          sheet2[sheet_index, 4] = format("%.2f", value.map(&:car_present_standard).map(&:to_f).inject(&:+).to_f)
          sheet2[sheet_index, 7] = format("%.2f", value.map(&:car_present).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        filename = "#{month}车勤补贴.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end


      def export_permit_entry(allowances, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/permit_entry.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1
        sheet2 = book.worksheet 2

        allowances = allowances.select{|r| r.permit_entry.to_f + r.try_drive.to_f + r.part_permit_entry.to_f > 0}

        gongsi = allowances.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        chongqing = allowances.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}
        dep_hash = Department.includes(:grade).index_by(&:name)

        allowances.each_with_index do |allowance, index|
          sheet0.row(index + 1).height = 15

          allowance.department_name.split("-").each do |dep_name|
            grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
            if %w(分公司 一正级).include?(grade_name)
              sheet0[index + 1, 0] = dep_name
            elsif grade_name == '一副级'
              sheet0[index + 1, 1] = dep_name
            else
              sheet0[index + 1, 2] = dep_name
            end
          end

          sheet0[index + 1, 3] = allowance.position_name
          sheet0[index + 1, 4] = allowance.employee_no
          sheet0[index + 1, 5] = allowance.employee_name
          sheet0[index + 1, 6] = allowance.permit_entry_standard.to_f
          sheet0[index + 1, 7] = allowance.try_drive_standard.to_f
          sheet0[index + 1, 8] = allowance.part_permit_entry_standard.to_f
          sheet0[index + 1, 9] = allowance.notes
          sheet0[index + 1, 12] = allowance.permit_entry.to_f + allowance.try_drive.to_f + allowance.part_permit_entry.to_f
          sheet0[index + 1, 13] = allowance.employee.labor_relation.try(:display_name)
          sheet0[index + 1, 16] = allowance.salary_set_book
        end

        sheet_index = 1
        gongsi.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            salary.department_name.split("-").each do |dep_name|
              grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
              if %w(分公司 一正级).include?(grade_name)
                sheet1[sheet_index, 0] = dep_name
              elsif grade_name == '一副级'
                sheet1[sheet_index, 1] = dep_name
              else
                sheet1[sheet_index, 2] = dep_name
              end
            end

            sheet1[sheet_index, 3] = salary.position_name
            sheet1[sheet_index, 4] = salary.employee_no
            sheet1[sheet_index, 5] = salary.employee_name
            sheet1[sheet_index, 6] = salary.permit_entry_standard.to_f
            sheet1[sheet_index, 7] = salary.try_drive_standard.to_f
            sheet1[sheet_index, 8] = salary.part_permit_entry_standard.to_f
            sheet1[sheet_index, 9] = salary.notes
            sheet1[sheet_index, 12] = salary.permit_entry.to_f + salary.try_drive.to_f + salary.part_permit_entry.to_f
            
            sheet_index += 1
          end

          sheet1.row(sheet_index).height = 15

          sheet1[sheet_index, 0] = "#{key}  汇总"
          sheet1[sheet_index, 6] = format("%.2f", value.map(&:permit_entry_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 7] = format("%.2f", value.map(&:try_drive_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 8] = format("%.2f", value.map(&:part_permit_entry_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 12] = format("%.2f", value.map(&:permit_entry).map(&:to_f).inject(&:+).to_f + 
            value.map(&:try_drive).map(&:to_f).inject(&:+).to_f + value.map(&:part_permit_entry).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        sheet_index = 1
        chongqing.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            salary.department_name.split("-").each do |dep_name|
              grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
              if %w(分公司 一正级).include?(grade_name)
                sheet2[sheet_index, 0] = dep_name
              elsif grade_name == '一副级'
                sheet2[sheet_index, 1] = dep_name
              else
                sheet2[sheet_index, 2] = dep_name
              end
            end

            sheet2[sheet_index, 3] = salary.position_name
            sheet2[sheet_index, 4] = salary.employee_no
            sheet2[sheet_index, 5] = salary.employee_name
            sheet2[sheet_index, 6] = salary.permit_entry_standard.to_f
            sheet2[sheet_index, 7] = salary.try_drive_standard.to_f
            sheet2[sheet_index, 8] = salary.part_permit_entry_standard.to_f
            sheet2[sheet_index, 9] = salary.notes
            sheet2[sheet_index, 12] = salary.permit_entry.to_f + salary.try_drive.to_f + salary.part_permit_entry.to_f
            
            sheet_index += 1
          end

          sheet2.row(sheet_index).height = 15

          sheet2[sheet_index, 0] = "#{key}  汇总"
          sheet2[sheet_index, 6] = format("%.2f", value.map(&:permit_entry_standard).map(&:to_f).inject(&:+).to_f)
          sheet2[sheet_index, 7] = format("%.2f", value.map(&:try_drive_standard).map(&:to_f).inject(&:+).to_f)
          sheet2[sheet_index, 8] = format("%.2f", value.map(&:part_permit_entry_standard).map(&:to_f).inject(&:+).to_f)
          sheet2[sheet_index, 12] = format("%.2f", value.map(&:permit_entry).map(&:to_f).inject(&:+).to_f + 
            value.map(&:try_drive).map(&:to_f).inject(&:+).to_f + value.map(&:part_permit_entry).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        filename = "#{month}机务放行补贴.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_security_check(allowances, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/security_check.xls")
        sheet0 = book.worksheet 0

        allowances = allowances.select{|r| r.security_check.to_f > 0}

        dep_hash = Department.includes(:grade).index_by(&:name)

        allowances.each_with_index do |allowance, index|
          sheet0.row(index + 1).height = 15

          allowance.department_name.split("-").each do |dep_name|
            grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
            if %w(分公司 一正级).include?(grade_name)
              sheet0[index + 1, 5] = dep_name
            elsif grade_name == '一副级'
              sheet0[index + 1, 2] = dep_name
            else
              sheet0[index + 1, 2] ||= dep_name
            end
          end

          sheet0[index + 1, 0] = allowance.employee_no
          sheet0[index + 1, 1] = allowance.employee_name
          sheet0[index + 1, 3] = allowance.position_name
          sheet0[index + 1, 4] = allowance.employee.labor_relation.try(:display_name)
          sheet0[index + 1, 6] = allowance.security_check_standard.to_f
          sheet0[index + 1, 9] = allowance.security_check.to_f
          sheet0[index + 1, 11] = allowance.notes
          sheet0[index + 1, 13] = allowance.salary_set_book
        end

        filename = "#{month}安检津贴.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_fly_honor(allowances, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/fly_honor.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1

        allowances = allowances.select{|r| r.fly_honor.to_f > 0}

        gongsi = allowances.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        chongqing = allowances.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}

        sheet_index = 1
        gongsi.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            sheet0[sheet_index, 0] = salary.department_name
            sheet0[sheet_index, 1] = salary.employee_name
            sheet0[sheet_index, 2] = salary.employee_no
            sheet0[sheet_index, 3] = salary.fly_honor_standard.to_f
            sheet0[sheet_index, 6] = salary.fly_honor.to_f
            sheet0[sheet_index, 7] = salary.notes
            sheet0[sheet_index, 9] = salary.salary_set_book
            
            sheet_index += 1
          end

          sheet0.row(sheet_index).height = 15

          sheet0[sheet_index, 0] = "#{key}  汇总"
          sheet0[sheet_index, 3] = format("%.2f", value.map(&:fly_honor_standard).map(&:to_f).inject(&:+).to_f)
          sheet0[sheet_index, 6] = format("%.2f", value.map(&:fly_honor).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        sheet_index = 1
        chongqing.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            sheet1[sheet_index, 0] = salary.department_name
            sheet1[sheet_index, 1] = salary.employee_name
            sheet1[sheet_index, 2] = salary.employee_no
            sheet1[sheet_index, 3] = salary.fly_honor_standard.to_f
            sheet1[sheet_index, 6] = salary.fly_honor.to_f
            sheet1[sheet_index, 7] = salary.notes
            sheet1[sheet_index, 9] = salary.salary_set_book
            
            sheet_index += 1
          end

          sheet1.row(sheet_index).height = 15

          sheet1[sheet_index, 0] = "#{key}  汇总"
          sheet1[sheet_index, 3] = format("%.2f", value.map(&:fly_honor_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 6] = format("%.2f", value.map(&:fly_honor).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        filename = "#{month}飞行安全荣誉津贴.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_communication(allowances, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/communication.xls")
        sheet0 = book.worksheet 0

        allowances = allowances.select{|r| r.communication.to_f > 0}

        allowances.each_with_index do |allowance, index|
          sheet0.row(index + 1).height = 15

          sheet0[index + 1, 1] = allowance.employee_no
          sheet0[index + 1, 2] = allowance.department_name
          sheet0[index + 1, 3] = allowance.employee_name
          sheet0[index + 1, 4] = allowance.employee.labor_relation.try(:display_name)
          sheet0[index + 1, 5] = allowance.employee.duty_rank.try(:display_name)
          sheet0[index + 1, 8] = allowance.position_name
          sheet0[index + 1, 9] = allowance.employee.position_remark
          sheet0[index + 1, 10] = allowance.communication_standard.to_f
          sheet0[index + 1, 12] = allowance.communication.to_f
          sheet0[index + 1, 13] = allowance.notes
          sheet0[index + 1, 15] = %w(重庆合同工 重庆合同制).include?(allowance.salary_set_book) ? "*" : nil
          sheet0[index + 1, 16] = allowance.salary_set_book
          sheet0[index + 1, 17] = allowance.employee.location
        end

        filename = "#{month}通讯补贴.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_resettlement(allowances, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/resettlement.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1
        sheet2 = book.worksheet 2

        allowances = allowances.select{|r| r.resettlement.to_f > 0}

        gongsi = allowances.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        chongqing = allowances.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}

        sheet_index = 1
        allowances.each do |allowance|
          sheet0.row(sheet_index).height = 15

          sheet0[sheet_index, 0] = allowance.department_name.split("-").first
          sheet0[sheet_index, 1] = allowance.employee_name
          sheet0[sheet_index, 2] = allowance.resettlement_standard.to_f
          sheet0[sheet_index, 5] = allowance.resettlement.to_f
          sheet0[sheet_index, 6] = allowance.notes
          sheet0[sheet_index, 8] = allowance.salary_set_book

          sheet_index += 1
        end
        sheet0.merge_cells sheet_index, 0, sheet_index, 1
        sheet0[sheet_index, 0] = '合计'
        sheet0[sheet_index, 2] = format("%.2f", allowances.map(&:resettlement_standard).map(&:to_f).inject(&:+).to_f)
        sheet0[sheet_index, 5] = format("%.2f", allowances.map(&:resettlement).map(&:to_f).inject(&:+).to_f)

        sheet_index = 1
        gongsi.each do |allowance|
          sheet1.row(sheet_index).height = 15

          sheet1[sheet_index, 0] = allowance.department_name.split("-").first
          sheet1[sheet_index, 1] = allowance.employee_name
          sheet1[sheet_index, 2] = allowance.resettlement_standard.to_f
          sheet1[sheet_index, 5] = allowance.resettlement.to_f
          sheet1[sheet_index, 6] = allowance.notes
          sheet1[sheet_index, 8] = allowance.salary_set_book

          sheet_index += 1
        end
        sheet1.merge_cells sheet_index, 0, sheet_index, 1
        sheet1[sheet_index, 0] = '合计'
        sheet1[sheet_index, 2] = format("%.2f", gongsi.map(&:resettlement_standard).map(&:to_f).inject(&:+).to_f)
        sheet1[sheet_index, 5] = format("%.2f", gongsi.map(&:resettlement).map(&:to_f).inject(&:+).to_f)

        sheet_index = 1
        chongqing.each do |allowance|
          sheet2.row(sheet_index).height = 15

          sheet2[sheet_index, 0] = allowance.department_name.split("-").first
          sheet2[sheet_index, 1] = allowance.employee_name
          sheet2[sheet_index, 2] = allowance.resettlement_standard.to_f
          sheet2[sheet_index, 5] = allowance.resettlement.to_f
          sheet2[sheet_index, 6] = allowance.notes
          sheet2[sheet_index, 8] = allowance.salary_set_book

          sheet_index += 1
        end
        sheet2.merge_cells sheet_index, 0, sheet_index, 1
        sheet2[sheet_index, 0] = '合计'
        sheet2[sheet_index, 2] = format("%.2f", chongqing.map(&:resettlement_standard).map(&:to_f).inject(&:+).to_f)
        sheet2[sheet_index, 5] = format("%.2f", chongqing.map(&:resettlement).map(&:to_f).inject(&:+).to_f)

        filename = "#{month}安置补贴.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_group_leader(allowances, month)
        book = Spreadsheet.open("#{Rails.root}/public/template/group_leader.xls")
        sheet0 = book.worksheet 0
        sheet1 = book.worksheet 1
        sheet2 = book.worksheet 2

        allowances = allowances.select{|r| r.group_leader.to_f + r.air_station_manage.to_f + r.cq_part_time_fix_car_subsidy.to_f > 0}
        gongsi = allowances.select{|r| %w(合同工 合同制).include?(r.salary_set_book)}
        chongqing = allowances.select{|r| %w(重庆合同工 重庆合同制).include?(r.salary_set_book)}

        dep_hash = Department.includes(:grade).index_by(&:name)

        allowances.each_with_index do |allowance, index|
          sheet0.row(index + 1).height = 15

          allowance.department_name.split("-").each do |dep_name|
            grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
            if %w(分公司 一正级).include?(grade_name)
              sheet0[index + 1, 1] = dep_name
            elsif grade_name == '一副级'
              sheet0[index + 1, 3] = dep_name
            else
              sheet0[index + 1, 3] ||= dep_name
            end
          end

          sheet0[index + 1, 0] = allowance.employee_no
          sheet0[index + 1, 2] = allowance.employee_name
          sheet0[index + 1, 4] = allowance.position_name
          sheet0[index + 1, 5] = allowance.employee.labor_relation.try(:display_name)
          sheet0[index + 1, 6] = allowance.group_leader_standard.to_f
          sheet0[index + 1, 7] = allowance.air_station_manage_standard.to_f
          sheet0[index + 1, 8] = allowance.cq_part_time_fix_car_subsidy_standard.to_f
          sheet0[index + 1, 9] = allowance.notes
          sheet0[index + 1, 11] = allowance.group_leader.to_f + allowance.air_station_manage.to_f + allowance.cq_part_time_fix_car_subsidy.to_f
          sheet0[index + 1, 14] = allowance.salary_set_book
        end

        sheet_index = 1
        gongsi.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            salary.department_name.split("-").each do |dep_name|
              grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
              if %w(分公司 一正级).include?(grade_name)
                sheet1[sheet_index, 1] = dep_name
              elsif grade_name == '一副级'
                sheet1[sheet_index, 3] = dep_name
              else
                sheet1[sheet_index, 3] ||= dep_name
              end
            end

            sheet1[sheet_index, 0] = salary.employee_no
            sheet1[sheet_index, 2] = salary.employee_name
            sheet1[sheet_index, 4] = salary.position_name
            sheet1[sheet_index, 5] = salary.employee.labor_relation.try(:display_name)
            sheet1[sheet_index, 6] = salary.group_leader_standard.to_f
            sheet1[sheet_index, 7] = salary.air_station_manage_standard.to_f
            sheet1[sheet_index, 8] = salary.cq_part_time_fix_car_subsidy_standard.to_f
            sheet1[sheet_index, 9] = salary.notes
            sheet1[sheet_index, 11] = salary.group_leader.to_f + salary.air_station_manage.to_f + salary.cq_part_time_fix_car_subsidy.to_f
            
            sheet_index += 1
          end

          sheet1.row(sheet_index).height = 15

          sheet1[sheet_index, 1] = "#{key}  汇总"
          sheet1[sheet_index, 6] = format("%.2f", value.map(&:group_leader_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 7] = format("%.2f", value.map(&:air_station_manage_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 8] = format("%.2f", value.map(&:cq_part_time_fix_car_subsidy_standard).map(&:to_f).inject(&:+).to_f)
          sheet1[sheet_index, 11] = format("%.2f", value.map(&:group_leader).map(&:to_f).inject(&:+).to_f + 
            value.map(&:air_station_manage).map(&:to_f).inject(&:+).to_f + value.map(&:cq_part_time_fix_car_subsidy).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end

        sheet_index = 1
        chongqing.group_by{|allowance| allowance.department_name.split("-").first}.each do |key, value|
          value.each do |salary|
            salary.department_name.split("-").each do |dep_name|
              grade_name = dep_hash[dep_name].try(:grade).try(:display_name)
              if %w(分公司 一正级).include?(grade_name)
                sheet2[sheet_index, 1] = dep_name
              elsif grade_name == '一副级'
                sheet2[sheet_index, 3] = dep_name
              else
                sheet2[sheet_index, 3] ||= dep_name
              end
            end

            sheet2[sheet_index, 0] = salary.employee_no
            sheet2[sheet_index, 2] = salary.employee_name
            sheet2[sheet_index, 4] = salary.position_name
            sheet2[sheet_index, 5] = salary.employee.labor_relation.try(:display_name)
            sheet2[sheet_index, 6] = salary.group_leader_standard.to_f
            sheet2[sheet_index, 7] = salary.air_station_manage_standard.to_f
            sheet2[sheet_index, 8] = salary.cq_part_time_fix_car_subsidy_standard.to_f
            sheet2[sheet_index, 9] = salary.notes
            sheet2[sheet_index, 11] = salary.group_leader.to_f + salary.air_station_manage.to_f + salary.cq_part_time_fix_car_subsidy.to_f
            
            sheet_index += 1
          end

          sheet2.row(sheet_index).height = 15

          sheet2[sheet_index, 1] = "#{key}  汇总"
          sheet2[sheet_index, 6] = format("%.2f", value.map(&:group_leader_standard).map(&:to_f).inject(&:+).to_f)
          sheet2[sheet_index, 7] = format("%.2f", value.map(&:air_station_manage_standard).map(&:to_f).inject(&:+).to_f)
          sheet2[sheet_index, 8] = format("%.2f", value.map(&:cq_part_time_fix_car_subsidy_standard).map(&:to_f).inject(&:+).to_f)
          sheet2[sheet_index, 11] = format("%.2f", value.map(&:group_leader).map(&:to_f).inject(&:+).to_f + 
            value.map(&:air_station_manage).map(&:to_f).inject(&:+).to_f + value.map(&:cq_part_time_fix_car_subsidy).map(&:to_f).inject(&:+).to_f)
          sheet_index += 1
        end


        filename = "#{month}班组长津贴.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      private
      def write_nc_xls(sheet, records, columns)
        records.each_with_index do |record, index|
          money = columns.inject([]){|arr, column| arr << record.send(column).to_f}.inject(&:+).to_f
          sheet[index + 1, 1] = record.employee_no
          sheet[index + 1, 2] = format("%.2f", money)
        end
      end

      def write_communication_nc_xls(sheet, records, special_type)
        index = 0
        records.each do |record|
          money = record.communication.to_f
          money = money - 400 > 0 ? money - 400 : 0 if special_type == 2
          money = money - 400 > 0 ? 400 : money if special_type == 3

          if money > 0
            sheet[index + 1, 1] = record.employee_no
            sheet[index + 1, 2] = format("%.2f", money)
            index += 1
          end
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