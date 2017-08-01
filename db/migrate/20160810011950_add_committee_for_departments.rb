class AddCommitteeForDepartments < ActiveRecord::Migration
  def change
  	add_column :departments, :committee, :boolean, default: false, index: true, comment: '是否特殊显示'

  	Department.where("name in (?)", ["党委办公室", "纪检/监察办公室", "女职工委员会", "团委（青年工作部）", "工会办公室"]).update_all(committee: true)
  end
end
