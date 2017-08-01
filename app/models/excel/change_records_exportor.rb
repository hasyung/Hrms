require 'spreadsheet'

module Excel
  class ChangeRecordsExportor
    COLUMNS = ['异动类型', '异动时间', '异动数据']

    class << self
      def export(change_records)
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

        change_records.each_with_index do |record, index|
          sheet.row(index + 1).height = 15

          sheet[index + 1, 0] = record.change_type
          sheet[index + 1, 1] = record.event_time.to_s(:db)
          sheet[index + 1, 2] = record.change_data.to_s
        end unless change_records.blank?

        filename = CGI::escape("#{Time.now.to_i}异动记录.xls")
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end
    end

  end
end
