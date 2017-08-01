require "csv"

namespace :import do
  task employee_classification: :environment do
    Employee.transaction do  
      CSV.foreach("#{Rails.root}/public/employee_classification.csv") do |row|
        name, classification = row[0].split(' ')
        employee = Employee.find_by(name: name)

        puts "姓名: #{name}, 类别：#{classification}"
        
        if employee && classification
          employee.update!(classification: classification)
        end
      end
    end
  end
end