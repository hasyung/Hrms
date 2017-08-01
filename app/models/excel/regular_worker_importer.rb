module Excel
  class RegularWorkerImporter
    attr_reader :errors
    
    def initialize(file_path)
      @sheet = Spreadsheet.open(file_path).worksheet(0)
      @data = []
      @errors = []
    end

    def import
      Employee.transaction do 
        @data.each do |data|
          data[:employee].update!(
            labor_relation_id: data[:labor_relation_id], 
            join_scal_date: data[:join_scal_date], 
            start_work_date: data[:start_work_date]
          )
        end
      end
    end

    def valid?
      @errors.empty?
    end

    def parse_data
      @sheet.each_with_index do |col, index|
        next if index == 0
        
        puts "解析#{index}行"
        error = "第#{index}行："

        unless col[0] && col[1] && col[2] && col[3] && col[4]
          error << "所有列必须填写完整；" 
          @errors << error
          next
        end

        employee = Employee.where(employee_no: col[0], name: col[1]).first
        error << "员工#{col[1]}不存在; " unless employee
        error << "用工性质#{col[2]}填写错误；" unless Employee::LaborRelation.find_by(display_name: col[2])
        error << "到岗日期必须为日期格式" unless col[3].class == Date
        error << "参工日期必须为日期格式" unless col[4].class == Date

        if error == "第#{index}行："
          @data << {
            employee: employee, 
            labor_relation_id: Employee::LaborRelation.find_by(display_name: col[2]).id, 
            join_scal_date: col[3],
            start_work_date: col[4]
          }
        else
          @errors << error
        end
      end
    end
  end
end