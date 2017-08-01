class UpdateData < ActiveRecord::Migration
  def change
    sql = <<-SQL
      UPDATE change_records SET is_pushed = true;
    SQL
    execute(sql)

  end
end
