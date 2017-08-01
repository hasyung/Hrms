# t.string :role_name #角色名称
# t.string :position_ids #岗位集合
# t.string :desc #描述
# t.string :flow_type #flow-type(流程类型)：Flow::AdjustPosition/Flow::EarlyRetirement
# t.integer :department_id #所属部门ID

class FlowRelation < ActiveRecord::Base
  serialize :position_ids, Array
  belongs_to :department

  ROLE_NAME = [
    ["HR专员", "department_hr"], ["劳动关系科科员", "hr_labor_relation_member"],
    ["党委人员", "party_member"], ["人力资源部领导", "hr_leader"],
    ["培训科室人员", "training_member"],
    ["薪酬室管理员", "hr_payment_member"], ["档案管理员", "file_manager"],
    ["部门领导", "department_leader"], ["公司领导", "company_leader"],
    ["人力资源部普通员工", "hr_normal"], ["福利室管理员", "welfare_member"], 
    ["科室领导", "family_leader"], ["分管领导", "county_leader"]
  ]

  class << self
    def get_department_leader_dep_id(employee)
      position_ids = []
      arrays = self.where(role_name: "department_leader").map(&:position_ids).flatten.map(&:to_i)
      employee.positions.each do |item|
        position_ids << item.id if arrays.include?(item.id)
      end
      department_ids = []
      position_ids.each do |position_id|
        department_ids << self.where(role_name: 'department_leader').where("position_ids like '%#{position_id}%'").first.department_id
      end
      department_ids
    end

    def get_role_name(role_name)
      ROLE_NAME.rassoc(role_name)[0]
    end

    def roles
      FlowRelation::ROLE_NAME.inject(['new_employee']){|arr, role|arr << role[1]}
    end

    def role_names
      FlowRelation::ROLE_NAME + [["新进员工", "new_employee"]]
    end

    def get_deps_department_hr(employee)
      deps = []
      employee.positions.map(&:id).each do |pos_id|
        deps = deps | FlowRelation.where('role_name = "department_hr" and position_ids like "%- ?\n%"', pos_id.to_s).map(&:department_id)
      end
      deps
    end

    def remove_relation(positions)
      positions.each do |pos|
        @relations = FlowRelation.all.select { |item| item.position_ids.include? (pos.id.to_s) }
        @relations.each do |relation|
          relation.position_ids.delete(pos.id.to_s)
          relation.save
        end
      end
    end
  end
end
