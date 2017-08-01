require 'spreadsheet'

module Excel
  class DinnerSettleImporter
    def self.import_north_part_detail(file_path, month)
      @category = '北头明细'
      DinnerRecord.where(category: @category, month: month).delete_all

      sheet = open_excel(file_path, month)

      DinnerSettle.transaction do
        sheet.each_with_index do |row, index|
          next unless row[0].present?
          next if row[0].include?("帐号")
          puts "处理第 #{index} 行"

          hash = {
            category: @category,
            month: month,
            employee_no: row[0].strip,
            employee_name: row[1].strip,
            record_date: row[2],
            real_time: row[3].strip,
            time_range: row[4],
            record_type: row[5].strip,
            computer_no: row[6],
            pos_no: row[7],
            amount: row[8],
            store_balance: row[9],
            operator: row[10].strip
          }

          DinnerRecord.create(hash)
        end
      end
    end

    def self.import_north_part_total(file_path, month)
      @employee_charge_total = 0
      @consume_total = 0

      sheet = open_excel(file_path, month)
      sheet.each_with_index do |row, index|
        next unless row.present?

        if row[0] && row[0].strip.gsub(' ', '') == '合计'
          @consume_total = row[4].to_f
        end

        if row[1] && row[1].strip.gsub(' ', '') == '职工现金充值'
          @employee_charge_total = row[7].to_f
        end
      end

      @dinner_record_stat = DinnerRecordStat.find_or_initialize_by(category: '北头总额', month: month)
      @dinner_record_stat.employee_charge_total = @employee_charge_total
      @dinner_record_stat.consume_total = @consume_total
      @dinner_record_stat.save
    end

    def self.import_office_detail(file_path, month)
      @category = '机关明细'
      DinnerRecord.where(category: @category, month: month).delete_all

      sheet = open_excel(file_path, month)

      DinnerSettle.transaction do
        sheet.each_with_index do |row, index|
          next unless row[0].present?
          next if row[0].include?("帐号")
          puts "处理第 #{index} 行"

          hash = {
            category: @category,
            month: month,
            employee_no: row[0].strip,
            employee_name: row[1].strip,
            record_date: row[2],
            real_time: row[3].strip,
            time_range: row[4],
            record_type: row[5].strip,
            computer_no: row[6],
            pos_no: row[7],
            amount: row[8],
            store_balance: row[9],
            operator: row[10].strip
          }

          DinnerRecord.create(hash)
        end
      end
    end

    def self.import_office_total(file_path, month)
      @employee_charge_total = 0
      @consume_total = 0
      @airline_pos_list = []
      @political_pos_list = []

      sheet = open_excel(file_path, month)
      sheet.each_with_index do |row, index|
        next unless row.present?

        if row[0] && row[0].strip.gsub(' ', '') == '合计'
          @consume_total = row[4].to_f
        end

        if row[1] && row[1].strip.gsub(' ', '') == '职工现金充值'
          @employee_charge_total = row[7].to_f
        end

        if row[1] && ["空勤午餐", "空勤晚餐"].include?(row[1].strip.gsub(' ', ''))
          @airline_pos_list << row[0].strip.gsub(' ', '')
        end

        if row[1] && ["行政午餐"].include?(row[1].strip.gsub(' ', ''))
          @political_pos_list << row[0].strip.gsub(' ', '')
        end
      end

      @dinner_record_stat = DinnerRecordStat.find_or_initialize_by(category: '机关总额', month: month)
      @dinner_record_stat.employee_charge_total = @employee_charge_total
      @dinner_record_stat.consume_total = @consume_total
      @dinner_record_stat.airline_pos_list = @airline_pos_list
      @dinner_record_stat.political_pos_list = @political_pos_list
      @dinner_record_stat.save
    end

    def self.import_cq_charge_table(file_path, month)
    end

    def self.import_km_charge_table(file_path, month)
    end

    private

    def self.open_excel(file_path, month)
      sheet = get_sheet(file_path)
      error_names, error_count = [], 0
      sheet
    end

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end
