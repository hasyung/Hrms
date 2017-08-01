class PositionChangeRecord < ActiveRecord::Base
  serialize :position_form, Array
  DIFF_ATTR = %W(channel_id category_id duty_rank_id classification location)

  belongs_to :employee
  belongs_to :operator, class_name: "Employee", foreign_key: "operator_id"

  before_save :setup_extra_info

  validates_presence_of :channel_id, :employee_id, :category_id, \
    :oa_file_no, :position_change_date, :probation_duration, :position_form

  # 参数ignore_audit表示是否要产生变更记录
  def active_change!(ignore_audit = 0, change_salary=true, is_changerecordweb = true)
    PositionChangeRecord.transaction do
      self.generate_new_change(ignore_audit)

      return true if self.is_finished

      employee = Employee.find(self.employee_id)
      origin_employee_positions = employee.employee_positions.pluck(:position_id, :category, :sort_index)
      new_employee_positions = self.position_form.inject([]) do |result, item|
        result << [item[:position_id], item[:category], item[:sort_index]]
        result
      end

      sorted_origin = origin_employee_positions.inject({}){|result, item| result["#{item[0]}/#{item[1]}"] = item; result}
      sorted_new = new_employee_positions.inject({}){|result, item| result["#{item[0]}/#{item[1]}"] = item; result}
      origin_keys = sorted_origin.keys
      new_keys = sorted_new.keys

      updated_keys = origin_keys & new_keys
      history_keys = origin_keys - updated_keys
      new_add_keys = new_keys - updated_keys

      updated_positions = updated_keys.inject([]){|result, key| val = sorted_new[key]; result << {position_id: val[0], sort_index: val[2]}; result }
      history_positions = history_keys.inject([]){|result, key| val = sorted_origin[key]; result << {position_id: val[0]}; result}
      new_positions = new_add_keys.inject([]){|result, key| val = sorted_new[key]; result << {position_id: val[0], category: val[1], sort_index: val[2]}; result}

      if self.salary_will_change
        # 如果主岗位变了，设置prev_department_id
        if master_position_changed?(new_positions)
          self.update!(prev_department_id: self.employee.department_id)
        end

        # 员工岗位（不论主岗位还是兼职等）修改高温补贴
        employee.salary_person_setup.update(temp_allowance: nil) if employee.salary_person_setup && new_positions.count != 0
        category = employee.category.try(:display_name)

        @channel_id_was = employee.channel_id
        @category_id_was = employee.category_id
        @department_name_was = employee.department.full_name
        @position_name_was = employee.master_position.name
        @location_was = employee.location

        # 修改人员数据
        employee.assign_attributes(
          position_remark: self.position_remark,
          channel_id:      self.channel_id,
          category_id:     self.category_id,
          duty_rank_id:    self.duty_rank_id,
          classification:  self.classification,
          location:        self.location
        )

        # 分类由员工变成干部（包括干部和领导）或是由干部变成员工我们才认为分类变化了
        is_category_changed = (employee.category_id_changed? && employee.category.display_name == "员工") || (category == "员工" && employee.category_id_changed? && employee.category.display_name != "员工")

        if change_salary
          if employee.location_changed?
            hash1 = {employee_id: employee.id, category: '属地变化', location_was: employee.location_was, prev_channel_id: employee.channel_id_was}
            Publisher.broadcast_event('SALARY_CHANGE', hash1)

            # 添加工作餐变动信息
            hash2 = {employee_id: employee.id, category: '属地变动', prev_channel_id: employee.channel_id_was}
            Publisher.broadcast_event('DINNER_CHANGE', hash2)
          end

          if employee.category_id_changed?
            hash = {employee_id: employee.id, category: '分类变动', prev_channel_id: employee.channel_id_was}
            Publisher.broadcast_event('SALARY_CHANGE', hash)
          end

          if employee.channel_id_changed?
            hash = {employee_id: employee.id, category: '通道变动', prev_channel_id: employee.channel_id_was}
            Publisher.broadcast_event('SALARY_CHANGE', hash)
          end

          if employee.duty_rank_id_changed?
            hash = {employee_id: employee.id, category: '职务职级变动', prev_channel_id: employee.channel_id_was}
            Publisher.broadcast_event('SALARY_CHANGE', hash)
          end

          if employee.classification_changed?
            hash = {employee_id: employee.id, category: '类别变动', prev_channel_id: employee.channel_id_was}
            Publisher.broadcast_event('SALARY_CHANGE', hash)
          end
        end

        if ignore_audit == 1
          employee.save_without_auditing
        else
          employee.save
        end

        # 找出历史主岗位
        history_position = employee.master_position
        position_name_history = history_position.name + "（" + history_position.department.full_name + "）"

        # 修改岗位
        # 找出历史岗位，置为工作经历
        history_positions.each do |item|
          position_id = item[:position_id]
          employee_position = EmployeePosition.find_by(employee_id: employee.id, position_id: position_id)
          employee_position.change_position(self.position_change_date, ignore_audit)
        end

        # 由于人员分类变了（分类由员工变为干部或领导），需要将工作经历改为任职记录
        if is_category_changed
          employee.work_experiences.where(end_date: "至今").each do |work|
            attributes = work.attributes.delete_if{|key, value| ["id", "created_at", "updated_at", "employee_category", "start_date"].include?(key)}
            work.update!(end_date: self.position_change_date)
            Employee::WorkExperience.create!(attributes.merge(start_date: self.position_change_date))
          end
        end

        new_positions.each do |item|
          employee_position = EmployeePosition.new(employee_id: employee.id, position_id: item[:position_id], category: item[:category], sort_index: item[:sort_index])

          if ignore_audit == 1
            employee_position.save_without_auditing
          else
            employee_position.save!
            employee_position.generate_work_experience(self.position_change_date)
          end
        end

        if change_salary
          if employee.master_position.name + "（" + employee.master_position.department.full_name + "）" != position_name_history
            # 产生薪酬异动记录
            hash1 = {
              employee_id: employee.id, 
              category: '岗位变动', 
              position_name_history: position_name_history, 
              position_change_record_id: self.id,
              prev_channel_id: @channel_id_was
            }
            Publisher.broadcast_event('SALARY_CHANGE', hash1)
          end

          @channel_id_was ||= employee.channel_id
          @category_id_was ||= employee.category_id
          @department_name_was ||= employee.department.full_name
          @position_name_was ||= employee.master_position.name
          @location_was ||= employee.location

          self.update(
            # prev_channel_id: @channel_id_was,
            prev_category_id: @category_id_was,
            prev_department_name: @department_name_was,
            prev_position_name: @position_name_was,
            prev_location: @location_was
          )

          if SalarySetupCache::CHANNEL_FULL_NAME.include?(CodeTable::Channel.find_by(id: employee.channel_id).try(:display_name)) && 
            SalarySetupCache::CHANNEL_FULL_NAME.include?(CodeTable::Channel.find_by(id: @channel_id_was).try(:display_name))
            salary_change_id = SalaryChange.where(employee_id: employee.id, category: '岗位变动').reorder(:created_at).last.try(:id)
            if employee.channel_id != @channel_id_was
              setup_cache = SalarySetupCache.find_or_create_by(employee_id: employee.id)

              if setup_cache.prev_channel_id == employee.channel_id
                setup_cache.destroy
              else
                setup_cache.assign_attributes(
                  position_change_date: self.position_change_date, 
                  probation_end_date: self.probation_end_date,
                  channel_id: employee.channel_id,
                  prev_channel_id: @channel_id_was,
                  prev_category_id: @category_id_was,
                  prev_department_name: @department_name_was,
                  prev_position_name: @position_name_was,
                  prev_location: @location_was,
                  salary_change_id: salary_change_id,
                  is_confirmed: false
                )
                setup_cache.change_data
                setup_cache.save
              end
            else
              setup_cache = SalarySetupCache.find_by(employee_id: employee.id)
              if setup_cache
                setup_cache.update(
                  position_change_date: self.position_change_date,
                  probation_end_date: self.probation_end_date,
                  salary_change_id: salary_change_id,
                  is_confirmed: false
                )
              end
            end
          end

          # 添加工作餐变动信息
          # hash2 = {employee_id: employee.id, category: '岗位变动'}
          # Publisher.broadcast_event('DINNER_CHANGE', hash2)
        end
      else
        employee.position_remark = self.position_remark

        if ignore_audit == 1
          employee.save_without_auditing
        else
          employee.save!
        end
      end

      # 需求变更: 即便是不影响薪酬，但是可能调整了顺序
      updated_positions.each do |item|
        employee_position = EmployeePosition.find_by(employee_id: employee.id, position_id: item[:position_id])
        employee_position.assign_attributes(sort_index: item[:sort_index])

        if ignore_audit == 1
          employee_position.save_without_auditing
        else
          employee_position.save!
        end
      end

      # 修改人员对应的sort_no
      master_position = employee.master_position
      employee.fix_sort_no_and_department_id(master_position.department_id)
      ChangeRecord.save_record('employee_update', employee, {position_oa_file: self.oa_file_no}).send_notification
      ChangeRecordWeb.save_record('employee_special', employee, {position_oa_file: self.oa_file_no}).send_notification if is_changerecordweb

      generate_set_book_change_record(self.prev_department_id, employee.department.id) if self.prev_department_id

      self.update!(is_finished: true)
    end
  end

  def check_position_remark
    return true if self.position_remark != self.employee.position_remark
    false
  end

  def check_diff
    has_diff = false
    employee = self.employee

    DIFF_ATTR.each do |attr_name|
      if self.send(attr_name) && employee.send(attr_name) != self.send(attr_name)
        self.salary_will_change = true
        has_diff = true and break
      end
    end

    unless has_diff
      employee_position_arr = employee.employee_positions.pluck(:position_id, :category).map{|item| item.join('/')}

      pos_arr = self.position_form.inject([]) do |result, pos_attr|
        result << "#{pos_attr[:position_id]}/#{pos_attr[:category]}"
        result
      end

      has_diff = true if employee_position_arr != pos_arr
      has_diff = true if employee_position_arr.count != pos_arr.count
      has_diff = true if (employee_position_arr - pos_arr).count != 0
    end

    has_diff ? (self.salary_will_change = true; return true) : (return false)
  end

  def generate_new_change(ignore_audit = 0)
    return if ignore_audit == 1
    emp = self.employee
    position_record = emp.position_records.create(
      employee_name:     emp.name,
      employee_no:       emp.employee_no,
      labor_relation_id: emp.labor_relation_id,
      gender_name:       emp.gender.try(:display_name),
      change_date:       self.position_change_date,
      oa_file_no:        self.oa_file_no,
      note:              self.probation_duration > 0 ? "试岗期#{self.probation_duration.to_s}月" : "",
    )

    pre_department_name = ''
    pre_position_name  = ''
    department_name = ''
    position_name = ''

    emp.employee_positions.each do |emp_pos|
      position = emp_pos.position
      pre_department_name = pre_department_name.blank? ? "#{position.department.full_name}(#{emp_pos.category})" : "#{pre_department_name}/#{position.department.full_name}(#{emp_pos.category})"
      pre_position_name = pre_position_name.blank? ? "#{position.name}(#{emp_pos.category})" : "#{pre_position_name}/#{position.name}(#{emp_pos.category})"
    end

    self.position_form.each do |item|
      position = Position.find item[:position_id]
      department_name = department_name.blank? ? "#{position.department.full_name}(#{item[:category]})" : "#{department_name}/#{position.department.full_name}(#{item[:category]})"
      position_name = position_name.blank? ? "#{position.name}(#{item[:category]})" : "#{position_name}/#{position.name}(#{item[:category]})"
    end

    position_record.update(
      pre_department_name: pre_department_name,
      pre_position_name:   pre_position_name,
      pre_category_name:   employee.category.try(:display_name),
      pre_channel_name:    employee.channel.try(:display_name),
      pre_location:        employee.location,
      pre_duty_rank_name:  employee.duty_rank.try(:display_name),
      pre_classification:  employee.classification,

      department_name: department_name,
      position_name:   position_name,
      category_name:   self.category_id.present? ? CodeTable::Category.find(self.category_id).try(:display_name) : employee.category.try(:display_name),
      channel_name:    self.channel_id.present? ? CodeTable::Channel.find(self.channel_id).try(:display_name) : employee.channel.try(:display_name),
      location:        self.location,
      duty_rank_name:  self.duty_rank_id.present? ? Employee::DutyRank.find(self.duty_rank_id).try(:display_name) : employee.duty_rank.try(:display_name),
      classification:  self.classification,
    )
  end

  protected
  def setup_extra_info
    self.probation_end_date = self.position_change_date.advance(months: self.probation_duration)
  end

  def master_position_changed?(form_data)
    master_position = form_data.select{|data| data[:category] == "主职"}.first
    master_position ? true : false
  end

  def generate_set_book_change_record(old_department_id, new_department_id)
    if self.employee.set_book_info.present?
      self.employee.set_book_info.generate_change_record(
        "update",
        {
          prev_department_id: old_department_id,
          department_id: new_department_id
        },
        true
      )
    end
  end
end
