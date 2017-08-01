class UpdateSalariesConfig < ActiveRecord::Migration
  def up
    sql = <<-SQL
      UPDATE salaries SET form_data = REPLACE(form_data, 'condition', 'X') WHERE category = "air_steward_base";
    SQL
    execute(sql)

    config = Salary.where(category: "service_c_base").first

    if config.present?
      config.form_data['flag_names']['X'] = 'X'
      config.save
    end
  end
end
