require 'spreadsheet'

module Excel
  class DinnerFeeImporter
    # 界面显示当前月的，但是操作者选择上月来进行
    def self.import_airline_backup(file_path, month)
      sheet = get_sheet(file_path)
      headers = ["昆备1", "蓉备1", "渝备1", "昆备2", "蓉备2", "渝备2"]
      @array = []
      @location_hash = employee_location_hash()

      sheet.each_with_index do |row, index|
        @employee_name = row[0]
        @employee_no = row[1]
        @amount = @count = 0

        [7, 8, 9, 10, 20, 21].each do |column|
          if [7, 8].include?(column)
            @location = '昆明'
          elsif [9, 10].include?(column)
            @location = '成都'
          elsif [20, 21].include?(column)
            @location = '重庆'
          end

          @employee_location = @location_hash[@employee_name].try(:location)
          @count += row[column].to_i if @employee_location.to_s == @location
        end

        @amount = @count * 20
        @array << {employee_no: @employee_no, employee_name: @employee_name, amount: @amount, backup_location: @employee_location, month: month}
      end

      @array
    end

    def self.import_air_security_backup(file_path, month)
      # 上个月
      month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")

      sheet = get_sheet(file_path)
      headers = ["A330备份", "备份", "兼职备份", "专职备份"]
      @array = []

      sheet.each_with_index do |row, index|
        @employee_name = row[0]
        @employee_no = row[1]
        @amount = @count = 0

        [2, 3, 5, 14].each do |column|
          @count += row[column].to_i
        end

        @amount = @count * 25
        @array << {employee_no: @employee_no, employee_name: @employee_name, amount: @amount, month: month}
      end

      @array
    end

    # 长水机场值班数据表
    def import_cs_airport_workovertime(file_path, month)
      #
    end

    private

    def self.employee_location_hash
      Employee.select("id, name, location").all.index_by(&:name)
    end

    def self.get_sheet(file_path)
      book = Spreadsheet.open("#{Rails.root}/public/#{file_path}")
      book.worksheet 0
    end
  end
end