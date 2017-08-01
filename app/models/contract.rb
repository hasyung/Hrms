class Contract < ActiveRecord::Base
  belongs_to :employee

  scope :expired, -> { where("end_date <= ? AND end_date >= ?", 30.days.ago.to_date, 60.days.since.to_date) }
  scope :existed, -> { where("employee_exists=1") }
  scope :actived, -> { where("status='在职'") }

  def contract_due_time_name
    self.contract_due_time > 0 ? self.contract_due_time : "无固定"
  end

  def contract_duration_date
    self.start_date.to_s + "至" + (self.end_date ? self.end_date.to_s : "无固定")
  end

  def judge_merge_contract
    @employee = Employee.unscoped.where(id: self.employee_id).first
    merge_item = @employee.last_merged_contract

    if merge_item.blank? #初始化
      merge_item = Contract.init_merge_contract(self)
      self.update(merged: true)
      return
    end

    if self.end_date != nil && merge_item.start_date > self.end_date
      Contract.init_merge_contract(self)
      self.update(merged: true)
      return
    end

    if merge_item.end_date != nil && self.end_date != nil
      if self.start_date <= merge_item.start_date && self.end_date >= merge_item.start_date && self.end_date < merge_item.end_date
        Contract.merge_contract(self, merge_item, "update_start_date")
      elsif self.start_date <= merge_item.start_date && self.end_date >= merge_item.end_date
        Contract.merge_contract(self, merge_item, "update_start_and_end_date")
      elsif self.start_date <= merge_item.end_date && self.end_date >= merge_item.end_date
        Contract.merge_contract(self, merge_item, "update_end_date")
      elsif self.start_date == merge_item.end_date || self.start_date == merge_item.end_date + 1.day
        Contract.merge_contract(self, merge_item, "update_end_date")
      elsif self.start_date > merge_item.end_date + 1.day
        Contract.init_merge_contract(self)
      end
    elsif merge_item.end_date != nil && self.end_date == nil
      if self.start_date <= merge_item.end_date + 1.day
        Contract.merge_contract(self, merge_item, "update_end_date")
      end
    else
      if self.start_date <= merge_item.start_date
        Contract.merge_contract(self, merge_item, "update_start_date")
      end
    end

    self.update(merged: true)
  end

  class << self
    def remerge_contract(employee_id)
      Contract.where(employee_id: employee_id, original: false).destroy_all

      employee = Employee.unscoped.where(id: employee_id).first
      contracts = employee.contracts.where(original: true).order(:start_date)

      contracts.each do |item|
        item.judge_merge_contract
      end
    end

    def init_merge_contract(contract)
      Contract.create(
        department_name: contract.department_name,
        position_name:   contract.position_name,
        employee_name:   contract.employee_name,
        apply_type:      contract.apply_type,
        change_flag:     contract.change_flag,
        contract_no:     contract.contract_no,
        start_date:      contract.start_date,
        end_date:        contract.end_date,
        employee_id:     contract.employee_id,
        employee_no:     contract.employee_no,
        employee_exists: contract.employee_exists,
        join_date:       contract.join_date,
        status:          contract.status,
        notes:           contract.notes,
        original:        false,
      )
    end

    def merge_contract(contract, merge_contract, type)
      case type
      when "update_end_date"
        hash = {
          department_name: contract.department_name,
          position_name:   contract.position_name,
          employee_name:   contract.employee_name,
          apply_type:      contract.apply_type,
          change_flag:     contract.change_flag,
          contract_no:     contract.contract_no,
          status:          contract.status,
          end_date:        contract.end_date,
          notes:           contract.notes.present? ? merge_contract.notes.to_s + "/" + contract.notes.to_s : "",
        }
      when "update_start_date"
        hash = {
          department_name: contract.department_name,
          position_name:   contract.position_name,
          employee_name:   contract.employee_name,
          apply_type:      contract.apply_type,
          change_flag:     contract.change_flag,
          contract_no:     contract.contract_no,
          status:          contract.status,
          start_date:      contract.start_date,
          notes:           contract.notes.present? ? merge_contract.notes.to_s + "/" + contract.notes.to_s : "",
        }
      when "update_start_and_end_date"
        hash = {
          department_name: contract.department_name,
          position_name:   contract.position_name,
          employee_name:   contract.employee_name,
          apply_type:      contract.apply_type,
          change_flag:     contract.change_flag,
          contract_no:     contract.contract_no,
          status:          contract.status,
          start_date:      contract.start_date,
          end_date:        contract.end_date,
          notes:           contract.notes.present? ? merge_contract.notes.to_s + "/" + contract.notes.to_s : "",
        }
      end

      merge_contract.update(hash)
    end

    #update contact when employee leave
    def update_status(employee, status)
      self.where(employee_no: employee.employee_no, employee_name: employee.name).update_all(
        status: status,
        employee_exists: false
      )
    end
  end
end
