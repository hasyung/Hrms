module Excel
  class PerformanceImporterBase
    attr_reader :errors
    
    def initialize(file, sheet_index=0)
      @data = Spreadsheet.open(file).worksheet(sheet_index)
      @last_row = @data.to_a.length - 1
      @errors = []
      @current_row_data = []
      @error_message = ''
      @employee = nil
    end

    def messages
      {
        success_count: (@last_row - @errors.count - 1),
        fail_count: @errors.count,
        errors: @errors
      }
    end

    private
    def attributes_valid?
      @employee = Employee.where(employee_no: @current_row_data[headers[:employee_no][:col_index]], name: @current_row_data[headers[:employee_name][:col_index]]).first
      @error_message = "#{@current_row_data[headers[:employee_name][:col_index]]}: "
      valid = true

      valid = false unless employee_valid?
      valid = false unless attributes_type_valid?        

      return valid
    end

    def employee_valid?
      valid = true

      if @employee.nil?
        @error_message << "人员#{@current_row_data[headers[:employee_name][:col_index]]}不存在; " 
        valid = false
      end

      return valid
    end

    def attributes_type_valid?
      valid = true
      
      headers.each do |key, value|
        col_value = @current_row_data[value[:col_index]]
        condition = !((col_value.nil? && value[:presence] == false) || (col_value.class == value[:type]))
        
        if condition
          @error_message << value[:msg] 
          valid = false
        end
      end

      return valid
    end
  end
end