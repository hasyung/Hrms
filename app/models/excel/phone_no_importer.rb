module Excel
  class PhoneNoImporter
    def self.import(file_path)
      @array = []
      @sheet = get_sheet file_path

      puts "开始导入通讯录，Email等信息"

      ActiveRecord::Base.transaction do
        @count = 0
        @sheet.each_with_index do |_row, _index|
          next if _index == 0
          @count += 1
          @employee = Employee.unscoped.includes(
            :contact
          ).where(
            employee_no: _row[4]
          ).first

          if @employee.present?
            @contact = @employee.contact
            _hash = {
              telephone: _row[17],
              mobile:    _row[14],
              email:     _row[18]
            }
            @contact.update(
              _hash.delete_if { |_k, _v| _v.blank? }
            )
          else
            @array << "#{_index+1}行 #{_row[3]} #{_row[4]} failed"
          end
        end

        if @array.size > 0
          puts @array.join("\r\n").red
          puts "提示：总共处理#{@count}行数据".yellow
          puts "警告: 有#{@array.size}行导入失败，失败率#{@array.size*100/@count}% \r\n\r\n".red
        end
      end
    end

    private
    def self.get_sheet(file_path)
      book = Spreadsheet.open(file_path)
      book.worksheet 0
    end
  end
end
