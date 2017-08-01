require 'spreadsheet'

module Excel
  class WelfareFeeExportor
    COLUMNS = %w(时间 福利费 社会保险费 公积金 企业年金)

    class << self
      def export(welfare_fees, year)
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
        welfare_fees.group_by{|welfare_fee| welfare_fee.month}.to_a.sort{|x, y| x[0] <=> y[0]}.to_h.each do |month, values|
          sheet.row(index + 1).height = 15
          sheet[index + 1, 0] = month

          values.each do |value|
            case value.category
            when '福利费'
              sheet[index + 1, 1] = value.fee
            when '社会保险费'
              sheet[index + 1, 2] = value.fee
            when '公积金'
              sheet[index + 1, 3] = value.fee
            when '企业年金'
              sheet[index + 1, 4] = value.fee
            end
          end

          index += 1
        end

        filename = "#{year}年福利费 #{Time.now.to_i}.xls"
        book.write("#{Rails.root}/public/export/tmp/#{filename}")
        {
          path: "#{Rails.root}/public/export/tmp/#{filename}",
          filename: filename
        }
      end
    end

  end
end
