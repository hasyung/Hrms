require 'spreadsheet'

module Excel
  class HoursFeeExportor
    CATEGORY = ['合同工', '合同制', '重庆合同工', '重庆合同制', '重庆合同制']
    OTHER_CATEGORY = ['合同工小时费', '合同工安飞奖', 
      '合同制小时费', '合同制安飞奖', 
      '重庆合同工小时费', '重庆合同工安飞奖', 
      '重庆合同制小时费', '重庆合同制安飞奖', 
      '重庆合同制小时费免税', '重庆合同制安飞奖免税']

    class << self

      def export_approval(month)
        book = Spreadsheet.open("#{Rails.root}/public/template/hours_fee.xls")
        sheet1 = book.worksheet 1
        sheet2 = book.worksheet 2

        feixing = HoursFee.joins(employee: :department).where("hours_fees.month = '#{month}' and 
          departments.full_name like '飞行部%'")
        kecang = HoursFee.joins(employee: :department).where("hours_fees.month = '#{month}' and 
          departments.full_name like '客舱服务部%'")
        kongbao = HoursFee.joins(employee: :department).where("hours_fees.month = '#{month}' and 
          departments.full_name like '空保大队%'")

        data = feixing.select{|f| %w(合同工 合同制).include?(f.salary_set_book)}
        num1 = get_total(data)
        data = kecang.select{|f| %w(合同工 合同制).include?(f.salary_set_book)}
        num2 = get_total(data)
        data = kongbao.select{|f| %w(合同工 合同制).include?(f.salary_set_book)}
        num3 = get_total(data)
        sheet1[1, 1], sheet1[2, 1], sheet1[3, 1] = num1, num2, num3
        sheet1[4, 1] = num1 + num2 + num3

        data = feixing.select{|f| %w(重庆合同工 重庆合同制).include?(f.salary_set_book)}
        num1 = get_total(data)
        data = kecang.select{|f| %w(重庆合同工 重庆合同制).include?(f.salary_set_book)}
        num2 = get_total(data)
        data = kongbao.select{|f| %w(重庆合同工 重庆合同制).include?(f.salary_set_book)}
        num3 = get_total(data)
        sheet2[1, 1], sheet2[2, 1], sheet2[3, 1] = num1, num2, num3
        sheet2[4, 1] = num1 + num2 + num3
      
        sheet1[9, 2] = sheet1[9, 2] = Date.current.to_s.gsub('-', '/') + '制'

        filename = "#{month.split('-').first}年#{month.split('-').last.to_i}月小时费打表.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end

      def export_nc(records, month)
        book1 = book2 = book3 = book4 = book5 = book6 = book7 = book8 = book9 = book10 = nil
        sheet1 = sheet2 = sheet3 = sheet4 = sheet5 = sheet6 = sheet7 = sheet8 = sheet9 = sheet10 = nil
        data1 = data2 = data3 = data4 = data5 = data6 = data7 = data8 = data9 = data10 = nil
        format_cell = Spreadsheet::Format.new :weight => :bold,
                                              :size => 14,
                                              :align => :center
        folder = "#{Rails.root}/public/export/tmp/hours_fees/"
        FileUtils.mkdir_p(folder + month) unless File.directory?(folder + month)
        input_filenames = []

        (1..10).each do |key|
          eval("book#{key} = Spreadsheet::Workbook.new")
          eval("sheet#{key} = book#{key}.create_worksheet")
          eval("sheet#{key}.row(0).default_format = format_cell")
          eval("sheet#{key}.row(0).height = 28")
          eval("['', '人员编码', '-'].each_with_index{|v, i| sheet#{key}.column(i).width = 15; 
            v= key%2==0 ? '安飞奖' : '小时费' if i==2; sheet#{key}.row(0).push(v)}")
          special_type = 1
          special_type = 2 if key == 7 or key == 8
          special_type = 3 if key == 9 or key == 10
          if special_type == 1 or special_type == 2
            eval("data#{key} = records.select{|r| r.salary_set_book == CATEGORY[#{(key + 1)/2 - 1}]}")
          else
            eval("data#{key} = records.select{|r| r.salary_set_book == CATEGORY[#{(key + 1)/2 - 1}] and r.hours_fee_category == '飞行员'}")
          end
          eval("write_nc_xls(sheet#{key}, data#{key}, key%2, special_type)")
          eval("book#{key}.write(folder + month + '/' + OTHER_CATEGORY[#{key - 1}] + '.xls')")
          input_filenames << OTHER_CATEGORY[key - 1] + '.xls'
        end

        zip_filename = "#{month}小时费NC表#{Time.now.to_s(:db)}.zip"
        creation_zip_file(folder, zip_filename, input_filenames, month)
        {
          path: folder + zip_filename,
          filename: zip_filename
        }
      end

      private
      def get_total(data)
        format("%.2f", data.map(&:fly_fee).map(&:to_f).inject(&:+))
      end

      def write_nc_xls(sheet, records, type, special_type)
        records.each_with_index do |record, index|
          sheet[index + 1, 1] = record.employee_no
          money = 0
          if type == 0
            money = record.total_security_fee.to_f
          else
            money = record.fly_fee.to_f - record.total_security_fee.to_f # + record.refund_fee.to_f
          end
          money = money*0.6 if special_type == 2 and record.hours_fee_category == '飞行员'
          money = money*0.4 if special_type == 3

          sheet[index + 1, 2] = format("%.2f", money)
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