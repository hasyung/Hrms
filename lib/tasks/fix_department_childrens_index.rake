namespace :fix_data do
  desc "fix dep childrens_index"
  task childrens_index: :environment do
    Department.all.each do |dep|
      array = dep.childrens.map(&:serial_number).map do |sn|
        sn[-3..-1].to_i
      end

      dep.update(childrens_index: array.max.to_i + 1) if dep.childrens.size > 0
    end
  end
end
