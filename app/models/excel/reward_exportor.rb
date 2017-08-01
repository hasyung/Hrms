module Excel
  class RewardExportor
    CATEGORY = ['合同工', '合同制', '重庆合同工', '重庆合同制']

    NC_CATEGORY = {
      'flight_bonus' => '航班正常奖',
      'service_bonus,brand_quality_fee' => '服务质量奖',
      'airline_security_bonus' => '日常航空安全奖',
      'composite_bonus' => '社会治安综合治理奖',
      'insurance_proxy' => '电子航意险代理提成奖',
      'cabin_grow_up' => '客舱升舱提成奖',
      'full_sale_promotion' => '全员促销奖',
      'article_fee' => '四川航空报稿费',
      'all_right_fly' => '无差错飞行中队奖',
      'year_composite_bonus' => '年度社会治安综合治理奖',
      'move_perfect' => '运兵先进奖',
      'security_special' => '航空安全特殊贡献奖',
      'dep_security_undertake' => '部门安全管理目标承包奖',
      'fly_star' => '飞行安全星级奖',
      'year_all_right_fly' => '年度无差错机务维修中队奖',
      'passenger_quarter_fee' => '客运目标责任书季度奖',
      'freight_quality_fee' => '货运目标责任书季度奖',
      'earnings_fee' => '收益奖励金',
      'off_budget_fee' => '内部奖惩',
      'save_oil_fee' => '节油奖',
      'cash_fine_fee' => '代扣',
    }

    class << self
      def export_nc(records, month)
        book1 = book2 = book3 = book4 = book5 = book6 = book7 = book8 = book9 = book10 = nil
        book11 = book12 = book13 = book14 = book15 = book16 = book17 = book18 = book19 = book20 = nil
        book21 = book22 = book23 = book24 = book25 = book26 = book27 = book28 = book29 = book30 = nil
        book31 = book32 = book33 = book34 = book35 = book36 = book37 = book38 = book39 = book40 = nil
        book41 = book42 = book43 = book44 = book45 = book46 = book47 = book48 = book49 = book50 = nil
        book51 = book52 = book53 = book54 = book55 = book56 = book57 = book58 = book59 = book60 = nil
        book61 = book62 = book63 = book64 = book65 = book66 = book67 = book68 = book69 = book70 = nil
        book71 = book72 = book73 = book74 = book75 = book76 = book77 = book78 = book79 = book80 = nil
        book81 = book82 = book83 = book84 = nil

        sheet1 = sheet2 = sheet3 = sheet4 = sheet5 = sheet6 = sheet7 = sheet8 = sheet9 = sheet10 = nil
        sheet11 = sheet12 = sheet13 = sheet14 = sheet15 = sheet16 = sheet17 = sheet18 = sheet19 = sheet20 = nil
        sheet21 = sheet22 = sheet23 = sheet24 = sheet25 = sheet26 = sheet27 = sheet28 = sheet29 = sheet30 = nil
        sheet31 = sheet32 = sheet33 = sheet34 = sheet35 = sheet36 = sheet37 = sheet38 = sheet39 = sheet40 = nil
        sheet41 = sheet42 = sheet43 = sheet44 = sheet45 = sheet46 = sheet47 = sheet48 = sheet49 = sheet50 = nil
        sheet51 = sheet52 = sheet53 = sheet54 = sheet55 = sheet56 = sheet57 = sheet58 = sheet59 = sheet60 = nil
        sheet61 = sheet62 = sheet63 = sheet64 = sheet65 = sheet66 = sheet67 = sheet68 = sheet69 = sheet70 = nil
        sheet71 = sheet72 = sheet73 = sheet74 = sheet75 = sheet76 = sheet77 = sheet78 = sheet79 = sheet80 = nil
        sheet81 = sheet82 = sheet83 = sheet84 = nil

        data1 = data2 = data3 = data4 = data5 = data6 = data7 = data8 = data9 = data10 = nil
        data11 = data12 = data13 = data14 = data15 = data16 = data17 = data18 = data19 = data20 = nil
        data21 = data22 = data23 = data24 = data25 = data26 = data27 = data28 = data29 = data30 = nil
        data31 = data32 = data33 = data34 = data35 = data36 = data37 = data38 = data39 = data40 = nil
        data41 = data42 = data43 = data44 = data45 = data46 = data47 = data48 = data49 = data50 = nil
        data51 = data52 = data53 = data54 = data55 = data56 = data57 = data58 = data59 = data60 = nil
        data61 = data62 = data63 = data64 = data65 = data66 = data67 = data68 = data69 = data70 = nil
        data71 = data72 = data73 = data74 = data75 = data76 = data77 = data78 = data79 = data80 = nil
        data81 = data82 = data83 = data84 = nil

        format_cell = Spreadsheet::Format.new :weight => :bold,
                                              :size => 14,
                                              :align => :center
        folder = "#{Rails.root}/public/export/tmp/allowances/"
        FileUtils.mkdir_p(folder + month) unless File.directory?(folder + month)
        input_filenames = []

        (1..21).each do |key|
          (1..4).each do |ke|
            eval("book#{key*ke} = Spreadsheet::Workbook.new")
            eval("sheet#{key*ke} = book#{key*ke}.create_worksheet")
            eval("sheet#{key*ke}.row(0).default_format = format_cell")
            eval("sheet#{key*ke}.row(0).height = 28")
            eval("['', '人员编码'].each_with_index{|v, i| sheet#{key*ke}.column(i).width = 15; 
              sheet#{key*ke}.row(0).push(v)}")
            eval("sheet#{key*ke}.column(2).width = 15; sheet#{key*ke}.row(0).push(NC_CATEGORY.values[#{key - 1}])")

            eval("data#{key*ke} = records.select{|r| r.salary_set_book == CATEGORY[#{ke - 1}] && 
              NC_CATEGORY.keys[#{key - 1}].split(',').inject([]){|arr, column| arr << r.send(column).to_f}.inject(&:+).to_f > 0}")
            eval("write_nc_xls(sheet#{key*ke}, data#{key*ke}, NC_CATEGORY.keys[#{key - 1}].split(','))")
            eval("book#{key*ke}.write(folder + month + '/' + NC_CATEGORY.values[#{key - 1}] + CATEGORY[#{ke - 1}] + '.xls')")
            input_filenames << NC_CATEGORY.values[key - 1] + CATEGORY[ke - 1] + '.xls'
          end
        end

        zip_filename = "#{month}奖励NC表#{Time.now.to_s(:db)}.zip"
        creation_zip_file(folder, zip_filename, input_filenames, month)
        {
          path: folder + zip_filename,
          filename: zip_filename
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
