class RoleMenu < ActiveRecord::Base
  serialize :menus, Hash

  MENU_CONFIG = {
      "待办事项" => [],
      "组织机构" => [],
      "岗位管理" => ["岗位列表", "岗位异动记录"],
      "人事信息" => ["人事花名册", "新员工列表", "人事变更信息"],
      "福利管理" => ["福利设置", "社保", "企业年金", "工作餐", "生育津贴"],
      "薪酬管理" => ["薪酬设置", "个人薪酬设置", "薪酬计算"],
      "劳动关系" => ["员工考勤", "员工调动", "员工退休", "员工退养", "员工辞退", "合同管理", "协议管理", "员工离职", "员工辞职", "客舱管理"],
      "绩效管理" => ["绩效记录", "绩效申诉", "绩效设置"],
      "科室管理" => ["报表管理"]
    }

  validates_uniqueness_of :role_name

  def self.get_menus_by_roles(roles)
    role_menus = RoleMenu.where("role_name in (?)", roles)
    keys = role_menus.inject([]){|arr, me| arr | me.menus.keys}
    roles_menu_config = keys.inject({}) do |hash, key|
      hash.merge!(key => role_menus.inject([]){|arr, me| arr | me.menus[key].to_a})
    end
    roles_menu_config || {}
  end
end
