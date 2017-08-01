class SalaryGradeChange < ActiveRecord::Base
  serialize :form_data, Hash

  belongs_to :employee

  def trigger_event(result)
    # TODO：
    # 1. 触发人员的薪酬设置的档级进行变动
    # 2. 发送消息
    ActiveRecord::Base.transaction do
      case result
      when true
        self.update(result: "通过变更")
        self.employee.salary_person_setup.update(
          self.form_data[:transfer_to].to_hash
        )
        self.employee.record_transfer_date if self.change_module == "岗位工资"
      when false
        self.update(result: "驳回变更")
      end
    end
  end
end
