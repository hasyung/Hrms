require 'spreadsheet'

module Excel
  module Salary
    class LeaderSalarySetupImporter
      def self.import(file_path)
        sheet = Spreadsheet.open(file_path).worksheet(0)

        @salary_hash = ::Salary.where("category LIKE '%_perf'").index_by(&:category)
        @performance_wages = {"信息" => "information_leader_perf", "航务航材" => "material_leader_perf",
          "机务" => "service_leader_perf", "管理" => "market_leader_perf", "营销" => "market_leader_perf"}

        Employee.transaction do
          @employee_hash = Employee.unscoped.includes(:salary_person_setup, :category).references(:salary_person_setup).index_by(&:employee_no)
          sheet.each_with_index do |row, index|
            next if index == 0 || index == 1 || row[10] == "飞行" || row[10] == "空勤"
            next if row[35].to_i == 0 && row[36].to_i == 0 && row[37].to_i == 0 && row[38].to_i == 0

            @employee = Employee.find_by(employee_no: row[1])
            category = row[10]
            performance_wage = @performance_wages[category]
            performance_channel = "X"
            amount_hash = {}
            @salary_hash[performance_wage][:form_data]["flags"].each do |grade, config|
              amount_hash[config['amount'].to_i] = grade
            end

            if row[41]
              performance_money = row[41].round.to_f
            else
              performance_money = row[38].round.to_f
            end
            performance_flag = amount_hash[performance_money.to_i].to_i

            if @employee.present?
              if @employee.salary_person_setup.nil?
                @setup = @employee.build_salary_person_setup
              else
                @setup = @employee.salary_person_setup
              end

              hash = {
                performance_wage: performance_wage,
                performance_money: performance_money,
                performance_flag: performance_flag,
                performance_channel: performance_channel
              }

              @setup.import_mode = true
              @setup.update(hash)
            else
              puts "#{index + 1} #{row[1]} #{row[6]}"
            end
          end
        end
      end
    end
  end
end
