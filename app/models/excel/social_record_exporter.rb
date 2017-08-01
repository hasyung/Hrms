require 'spreadsheet'

module Excel
  class SocialRecordExporter

    WITHHOLD_RECORD = ['人员编号', '社保编号', '姓名', '养老基数', '其他基数', '养老', '医疗', '失业', '补扣', '备注']
    WITHHOLD_SHANGLV = ['社保编号', '姓名', '养老基数', '其他基数', '公司', '个人', '公司', '个人', '公司', '公司', '个人', '公司', '公司']
    WITHHOLD_KONGJING = ['人员编号', '社保编号', '姓名', '基数', '养老', '医疗', '失业', '养老', '医疗', '失业']

    def self.export_record(records)
      book = Spreadsheet.open("#{Rails.root}/public/template/social_record.xls")
      sheet = book.worksheet 0

      total, total_company, total_personage = 0, 0, 0
      pension_company_total, pension_personage_total, treatment_company_total = 0, 0, 0
      treatment_personage_total, fertility_company_total, unemploy_company_total = 0, 0, 0
      unemploy_personage_total, injury_company_total, illness_company_total = 0, 0, 0

      records.each_with_index do |record, index|
        sheet.row(index + 3).height = 18

        sheet[index + 3, 0] = index + 1
        sheet[index + 3, 1] = record.employee_no
        sheet[index + 3, 2] = record.identity_no
        sheet[index + 3, 3] = record.employee_name
        sheet[index + 3, 4] = record.compute_month.gsub('-', '')
        sheet[index + 3, 5] = record.t_company
        sheet[index + 3, 6] = record.t_personage
        sheet[index + 3, 9] = record.t_company + record.t_personage
        sheet[index + 3, 13] = record.pension_cardinality
        sheet[index + 3, 14] = record.pension_company_scale
        sheet[index + 3, 15] = format("%.2f", record.pension_company_money)
        pension_company_total += record.pension_company_money

        sheet[index + 3, 16] = record.pension_personage_scale
        sheet[index + 3, 17] = format("%.2f", record.pension_personage_money)
        pension_personage_total += record.pension_personage_money

        sheet[index + 3, 23] = record.other_cardinality
        sheet[index + 3, 24] = record.treatment_company_scale
        sheet[index + 3, 25] = format("%.2f", record.treatment_company_money)
        treatment_company_total += record.treatment_company_money

        sheet[index + 3, 26] = record.treatment_personage_scale
        sheet[index + 3, 27] = format("%.2f", record.treatment_personage_money)
        treatment_personage_total += record.treatment_personage_money

        sheet[index + 3, 33] = record.other_cardinality
        sheet[index + 3, 34] = record.fertility_company_scale
        sheet[index + 3, 35] = format("%.2f", record.fertility_company_money)
        fertility_company_total += record.fertility_company_money

        sheet[index + 3, 40] = record.other_cardinality
        sheet[index + 3, 41] = record.employee.labor_relation.try(:display_name)
        sheet[index + 3, 42] = record.unemploy_company_scale
        sheet[index + 3, 43] = format("%.2f", record.unemploy_company_money)
        unemploy_company_total += record.unemploy_company_money

        sheet[index + 3, 44] = record.unemploy_personage_scale
        sheet[index + 3, 45] = format("%.2f", record.unemploy_personage_money)
        unemploy_personage_total += record.unemploy_personage_money

        sheet[index + 3, 50] = record.other_cardinality
        sheet[index + 3, 51] = record.injury_company_scale
        sheet[index + 3, 52] = format("%.2f", record.injury_company_money)
        injury_company_total += record.injury_company_money

        sheet[index + 3, 65] = record.other_cardinality
        sheet[index + 3, 66] = record.illness_company_scale
        sheet[index + 3, 67] = format("%.2f", record.illness_company_money)
        illness_company_total += record.illness_company_money

        total_company += record.t_company
        total_personage += record.t_personage
      end
      total = total_company + total_personage

      sheet[2, 5] = format("%.2f", total_company)
      sheet[2, 6] = format("%.2f", total_personage)
      sheet[2, 9] = format("%.2f", total)
      sheet[2, 15] = format("%.2f", pension_company_total)
      sheet[2, 17] = format("%.2f", pension_personage_total)
      sheet[2, 25] = format("%.2f", treatment_company_total)
      sheet[2, 27] = format("%.2f", treatment_personage_total)
      sheet[2, 35] = format("%.2f", fertility_company_total)
      sheet[2, 43] = format("%.2f", unemploy_company_total)
      sheet[2, 45] = format("%.2f", unemploy_personage_total)
      sheet[2, 52] = format("%.2f", injury_company_total)
      sheet[2, 67] = format("%.2f", illness_company_total)

      filename = records.first.compute_month.gsub('-', '') + '社保明细.xls'
      book.write(file_path + "#{filename}")
      {
        path: file_path + "#{filename}",
        filename: filename
      }
    end

    def self.export_declare(records)
      book = Spreadsheet::Workbook.new

      records.group_by{|record|record.social_location}.each do |location, arr|
        sheet = book.create_worksheet name: location

        sheet.row(0).default_format = Spreadsheet::Format.new :weight => :bold,
                                                              :size => 14,
                                                              :align => :center
        sheet.row(0).height = 28
        sheet.column(0).width = 15
        sheet.column(1).width = 15
        sheet.column(2).width = 15
        sheet.row(0).push '人员编号'
        sheet.row(0).push '姓名'
        sheet.row(0).push '基数'

        arr.each_with_index do |record, index|
          sheet.row(index + 1).height = 18
          sheet.row(index + 1).default_format.align = :center

          sheet.row(index + 1).push record.employee_no
          sheet.row(index + 1).push record.employee_name
          sheet.row(index + 1).push record.pension_cardinality
        end
      end

      filename = records.first.compute_month.gsub('-', '') + '社保申报.xls'
      book.write(file_path + "#{filename}")
      {
        path: file_path + "#{filename}",
        filename: filename
      }
    end

    def self.export_withhold(records)
      book = Spreadsheet::Workbook.new
      records.each_with_index do |_records, _index|
        next if _records.blank?

        sheet = book.create_worksheet
        case _index
        when 0
          sheet.name = '首页'
          write_withhold_record(sheet, _records)
        when 1
          sheet.name = '商旅'
          write_withhold_shanglv(sheet, _records)
        when 2
          sheet.name = '校修'
          write_withhold_xiaoxiu(sheet, _records)
        when 3
          sheet.name = '广告'
          write_withhold_xiaoxiu(sheet, _records)
        when 4
          sheet.name = '空警'
          write_withhold_kongjing(sheet, _records)
        end
      end

      filename = records.first.first.compute_month.gsub('-', '') + '社保代扣.xls'
      book.write(file_path + "#{filename}")
      {
        path: file_path + "#{filename}",
        filename: filename
      }
    end

    def self.write_withhold_record(sheet, records)
      sheet.row(0).default_format = Spreadsheet::Format.new :weight => :bold,
                                                            :size => 14,
                                                            :align => :center
      sheet.row(0).height = 28
      WITHHOLD_RECORD.each_with_index do |value, index|
        sheet.column(index).width = 15
        sheet.row(0).push(value)
      end

      records.each_with_index do |record, index|
        sheet.row(index + 1).height = 18
        sheet.row(index + 1).default_format.align = :center

        sheet.row(index + 1).push(record.employee_no)
        sheet.row(index + 1).push(record.social_account)
        sheet.row(index + 1).push(record.employee_name)
        sheet.row(index + 1).push(record.pension_cardinality)
        sheet.row(index + 1).push(record.other_cardinality)
        sheet.row(index + 1).push(format("%.2f", record.pension_personage_money))
        sheet.row(index + 1).push(format("%.2f", record.treatment_personage_money))
        sheet.row(index + 1).push(format("%.2f", record.unemploy_personage_money))
      end
    end

    def self.write_withhold_shanglv(sheet, records)
      set_format(sheet)

      set_special_company(sheet)

      pension_company_total, pension_personage_total, treatment_company_total = 0, 0, 0
      treatment_personage_total, fertility_company_total, unemploy_company_total = 0, 0, 0
      unemploy_personage_total, injury_company_total, illness_company_total = 0, 0, 0

      records.each_with_index do |record, index|
        sheet.row(index + 2).height = 18
        sheet.row(index + 2).default_format.align = :center

        sheet.row(index + 2).push(record.social_account)
        sheet.row(index + 2).push(record.employee_name)

        sheet.row(index + 2).push(record.pension_cardinality)
        sheet.row(index + 2).push(record.other_cardinality)
        sheet.row(index + 2).push(format("%.2f", record.pension_company_money))
        pension_company_total += record.pension_company_money
        sheet.row(index + 2).push(format("%.2f", record.pension_personage_money))
        pension_personage_total += record.pension_personage_money
        sheet.row(index + 2).push(format("%.2f", record.treatment_company_money))
        treatment_company_total += record.treatment_company_money
        sheet.row(index + 2).push(format("%.2f", record.treatment_personage_money))
        treatment_personage_total += record.treatment_personage_money
        sheet.row(index + 2).push(format("%.2f", record.illness_company_money))
        illness_company_total += record.illness_company_money
        sheet.row(index + 2).push(format("%.2f", record.unemploy_company_money))
        unemploy_company_total += record.unemploy_company_money
        sheet.row(index + 2).push(format("%.2f", record.unemploy_personage_money))
        unemploy_personage_total += record.unemploy_personage_money
        sheet.row(index + 2).push(format("%.2f", record.injury_company_money))
        injury_company_total += record.injury_company_money
        sheet.row(index + 2).push(format("%.2f", record.fertility_company_money))
        fertility_company_total += record.fertility_company_money
      end
      sheet.merge_cells(records.size + 2, 0, records.size + 2, 3)
      sheet[records.size + 2, 0] = '合计'

      sheet[records.size + 2, 1] = format("%.2f", pension_company_total)
      sheet[records.size + 2, 4] = format("%.2f", pension_personage_total)
      sheet[records.size + 2, 5] = format("%.2f", treatment_company_total)
      sheet[records.size + 2, 6] = format("%.2f", treatment_personage_total)
      sheet[records.size + 2, 7] = format("%.2f", illness_company_total)
      sheet[records.size + 2, 8] = format("%.2f", unemploy_company_total)
      sheet[records.size + 2, 9] = format("%.2f", unemploy_personage_total)
      sheet[records.size + 2, 10] = format("%.2f", injury_company_total)
      sheet[records.size + 2, 11] = format("%.2f", fertility_company_total)
    end

    def self.write_withhold_xiaoxiu(sheet, records)
      set_format(sheet)

      set_special_company(sheet)

      pension_company_total, treatment_company_total, fertility_company_total = 0, 0, 0
      unemploy_company_total, injury_company_total, illness_company_total = 0, 0, 0

      records.each_with_index do |record, index|
        sheet.row(index + 2).height = 18
        sheet.row(index + 2).default_format.align = :center

        sheet.row(index + 2).push(record.social_account)
        sheet.row(index + 2).push(record.employee_name)

        sheet.row(index + 2).push(record.pension_cardinality)
        sheet.row(index + 2).push(record.other_cardinality)
        sheet.row(index + 2).push(format("%.2f", record.pension_company_money))
        pension_company_total += record.pension_company_money
        sheet.row(index + 2).push("")

        sheet.row(index + 2).push(format("%.2f", record.treatment_company_money))
        treatment_company_total += record.treatment_company_money
        sheet.row(index + 2).push("")

        sheet.row(index + 2).push(format("%.2f", record.illness_company_money))
        illness_company_total += record.illness_company_money
        sheet.row(index + 2).push(format("%.2f", record.unemploy_company_money))
        unemploy_company_total += record.unemploy_company_money
        sheet.row(index + 2).push("")

        sheet.row(index + 2).push(format("%.2f", record.injury_company_money))
        injury_company_total += record.injury_company_money
        sheet.row(index + 2).push(format("%.2f", record.fertility_company_money))
        fertility_company_total += record.fertility_company_money
      end
      sheet.merge_cells(records.size + 2, 0, records.size + 2, 3)

      sheet[records.size + 2, 0] = '合计'
      sheet[records.size + 2, 4] = format("%.2f", pension_company_total)
      sheet[records.size + 2, 6] = format("%.2f", treatment_company_total)
      sheet[records.size + 2, 8] = format("%.2f", illness_company_total)
      sheet[records.size + 2, 9] = format("%.2f", unemploy_company_total)
      sheet[records.size + 2, 11] = format("%.2f", injury_company_total)
      sheet[records.size + 2, 12] = format("%.2f", fertility_company_total)
    end

    def self.write_withhold_kongjing(sheet, records)
      set_format(sheet)

      sheet.merge_cells 0, 4, 0, 6
      sheet.merge_cells 0, 7, 0, 9

      sheet[0, 4] = '当月应扣'
      sheet[0, 5] = '补扣金额'

      WITHHOLD_KONGJING.each_with_index do |value, index|
        sheet.column(index).width = 15
        sheet.row(1).push(value)
      end

      records.each_with_index do |record, index|
        sheet.row(index + 2).height = 18
        sheet.row(index + 2).default_format.align = :center

        sheet.row(index + 2).push(record.employee_no)
        sheet.row(index + 2).push(record.social_account)
        sheet.row(index + 2).push(record.employee_name)
        sheet.row(index + 2).push(record.other_cardinality)
        sheet.row(index + 2).push("")
        sheet.row(index + 2).push(format("%.2f", record.treatment_personage_money))
      end
    end

    def self.set_format(sheet)
      format = Spreadsheet::Format.new :weight => :bold,
                                       :size => 14,
                                       :align => :center
      sheet.row(0).default_format = sheet.row(1).default_format = format
      sheet.row(0).height = sheet.row(1).height = 28
    end

    def self.set_special_company(sheet)
      sheet.merge_cells 0, 4, 0, 5
      sheet.merge_cells 0, 6, 0, 7
      sheet.merge_cells 0, 9, 0, 10

      sheet[0, 4] = '养老'
      sheet[0, 6] = '医疗'
      sheet[0, 8] = '大病'
      sheet[0, 9] = '失业'
      sheet[0, 11] = '工伤'
      sheet[0, 12] = '生育'

      WITHHOLD_SHANGLV.each_with_index do |value, index|
        sheet.column(index).width = 15
        sheet.row(1).push(value)
      end
    end

    def self.file_path
      "#{Rails.root}/public/export/tmp/"
    end
  end
end