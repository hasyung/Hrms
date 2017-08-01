class CreateDepartmentSalaries < ActiveRecord::Migration
  def change
    create_table :department_salaries do |t|
      t.integer :department_id, index: true, null: false
      t.string  :category, index: true, comment: "类别"
      t.string  :month, index: true, comment: "月度"

      t.decimal :remain, precision: 10, scale: 2, default: 0, index: true, comment: "总留存"
      t.decimal :leader_remain, precision: 10, scale: 2, default: 0, index: true, comment: "干部留存"
      t.decimal :employee_remain, precision: 10, scale: 2, default: 0, index: true, comment: "员工留存"
      t.decimal :verify_limit, precision: 10, scale: 2, default: 0, index: true, comment: "总核定额度"
      t.decimal :leader_verify_limit, precision: 10, scale: 2, default: 0, index: true, comment: "干部核定额度"
      t.decimal :employee_verify_limit, precision: 10, scale: 2, default: 0, index: true, comment: "员工核定额度"

      t.decimal :flight_bonus, precision: 10, scale: 2, default: 0, index: true, comment: "航班正常奖"
      t.decimal :service_bonus, precision: 10, scale: 2, default: 0, index: true, comment: "服务质量奖"
      t.decimal :airline_security_bonus, precision: 10, scale: 2, default: 0, index: true, comment: "航空安全奖"
      t.decimal :composite_bonus, precision: 10, scale: 2, default: 0, index: true, comment: "社会治安综合治理奖"
      t.decimal :insurance_proxy, precision: 10, scale: 2, default: 0, index: true, comment: "电子航意险代理提成奖"
      t.decimal :cabin_grow_up, precision: 10, scale: 2, default: 0, index: true, comment: "客舱升舱提成奖"
      t.decimal :full_sale_promotion, precision: 10, scale: 2, default: 0, index: true, comment: "全员促销奖"
      t.decimal :article_fee, precision: 10, scale: 2, default: 0, index: true, comment: "四川航空报稿费"
      t.decimal :all_right_fly, precision: 10, scale: 2, default: 0, index: true, comment: "无差错飞行中队奖"
      t.decimal :year_composite_bonus, precision: 10, scale: 2, default: 0, index: true, comment: "年度综治奖"
      t.decimal :move_perfect, precision: 10, scale: 2, default: 0, index: true, comment: "运兵先进奖"
      t.decimal :security_special, precision: 10, scale: 2, default: 0, index: true, comment: "航空安全特殊贡献奖"
      t.decimal :dep_security_undertake, precision: 10, scale: 2, default: 0, index: true, comment: "部门安全管理目标承包奖"
      t.decimal :fly_star, precision: 10, scale: 2, default: 0, index: true, comment: "飞行安全星级奖"
      t.decimal :year_all_right_fly, precision: 10, scale: 2, default: 0, index: true, comment: "年度无差错机务维修中队奖"
      t.decimal :network_connect, precision: 10, scale: 2, default: 0, index: true, comment: "网络联程奖"
      t.decimal :quarter_fee, precision: 10, scale: 2, default: 0, index: true, comment: "季度奖"
      t.decimal :earnings_fee, precision: 10, scale: 2, default: 0, index: true, comment: "收益奖励金"

      t.timestamps null: false
    end

    remove_column :departments, :remain
    remove_column :departments, :leader_remain
    remove_column :departments, :employee_remain
  end

end
