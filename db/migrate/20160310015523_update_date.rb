class UpdateDate < ActiveRecord::Migration
  def change
    execute("UPDATE departments SET d1_sort_no = 37 WHERE d1_sort_no = 36 AND serial_number LIKE '000011%';")
    execute("DELETE FROM audits WHERE auditable_type = 'Employee::ContactWay' AND Date(created_at) = '2016-03-09' AND user_id IS NULL;")
    execute("DELETE FROM audits WHERE audited_changes LIKE '%special_ca%';")
  end
end
