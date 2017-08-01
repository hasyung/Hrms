require 'spreadsheet'

module Excel
  class LandAllowanceImporter
    def self.import_foc(type, file_path, month)
      sheet = get_sheet(file_path)
      LandRecord.where(category: type).delete_all
      landrecords = LandRecord.all
      LandAllowance.transaction do
        sheet.each_with_index do |row, index|
          next if row[1].blank?
          time_slot = []
          if row[0].to_s.include?('合计')
            next
          end

          if row[0].to_s == '序号'
            @cities = row
            next
          end

          @employee_name = row[1]


          row.each_with_index do |column, index|
            next if column.blank?
            next if index <= 2
            if column.present?
              days = column.split(')')[0].sub('(', '').sub('天', '')
              day_str = column.gsub("(#{days}天)", "")
              day_str.split(" ").each do |str|
                time_slot << str.split('`')
              end
            end
          end

          landrecords.each do |landrecord|
            if landrecord.employee_name == @employee_name.strip
              time_slot << landrecord.start_day
              time_slot << landrecord.end_day
            end
          end
            

          time_slot = time_slot.flatten.map{|t| t.to_i}

          row.each_with_index do |column, idx|
            next if column.blank?
            next if idx <= 2

            #(1天)31
            #(2天)22`23
            #(5天)1`3[单元格分隔符]6`7
            if column.present?
              @days = column.split(')')[0].sub('(', '').sub('天', '')

              day_str = column.gsub("(#{@days}天)", "")
              day_str.split(" ").each do |str|
                str = str.strip
                array = str.split('`')

                if array.size == 2
                  @start_day = array[0].strip.to_i
                  @end_day = ((array[1].strip.to_i >= "#{month}-01".to_date.end_of_month.strftime("%d").to_i || time_slot.include?(array[1].strip.to_i+1)) ? array[1].strip.to_i : array[1].strip.to_i + 1)
                  @days = @end_day - @start_day + 1
                else
                  @start_day = array[0].strip.to_i
                  @end_day = ((array[0].strip.to_i >= "#{month}-01".to_date.end_of_month.strftime("%d").to_i || time_slot.include?(array[0].strip.to_i+1)) ? array[0].strip.to_i : array[0].strip.to_i + 1)
                  @days = (@start_day == @end_day ? 1 : @end_day - @start_day +1)
                end

                hash = {
                  employee_name: @employee_name,
                  city: @cities[idx],
                  start_day: @start_day,
                  end_day: @end_day,
                  days: @days,
                  month: month,
                  category: type
                }

                LandRecord.create!(hash)
              end
            end
          end
        end
      end
    end

    private

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end
