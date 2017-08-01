json.salary_person_setup do
  employee = Employee.unscoped.find_by(id: @salary_person_setup.employee_id)
  json.partial! 'api/salary_person_setups/setup', salary: @salary_person_setup, employee: employee

  json.join_scal_date          employee.join_scal_date
  json.working_years_salary    @salary_person_setup.working_years_salary.try(:to_f)    ||   employee.working_years_salary
  json.base_wage               @salary_person_setup.base_wage
  json.base_channel            @salary_person_setup.base_channel
  json.base_flag               @salary_person_setup.base_flag
  json.base_money              @salary_person_setup.base_money.try(:to_f)
  json.reserve_wage            @salary_person_setup.reserve_wage.try(:to_f)
  json.performance_wage        @salary_person_setup.performance_wage
  json.performance_channel     @salary_person_setup.performance_channel
  json.performance_flag        @salary_person_setup.performance_flag
  json.performance_money       @salary_person_setup.performance_money.try(:to_f)
  json.security_subsidy        @salary_person_setup.security_subsidy
  json.leader_subsidy          @salary_person_setup.leader_subsidy
  json.terminal_subsidy        @salary_person_setup.terminal_subsidy
  json.ground_subsidy          @salary_person_setup.ground_subsidy
  json.machine_subsidy         @salary_person_setup.machine_subsidy
  json.trial_subsidy           @salary_person_setup.trial_subsidy
  json.honor_subsidy           @salary_person_setup.honor_subsidy
  json.placement_subsidy       @salary_person_setup.placement_subsidy
  json.car_subsidy             @salary_person_setup.car_subsidy
  json.fly_hour_fee            @salary_person_setup.fly_hour_fee
  json.fly_hour_money          @salary_person_setup.fly_hour_money
  json.airline_hour_fee        @salary_person_setup.airline_hour_fee
  json.airline_hour_money      @salary_person_setup.airline_hour_money
  json.security_hour_fee       @salary_person_setup.security_hour_fee
  json.security_hour_money     @salary_person_setup.security_hour_money
  json.land_type               @salary_person_setup.land_type
  json.limit_leader            @salary_person_setup.limit_leader
  json.refund_fee              @salary_person_setup.refund_fee.to_f
  json.temp_allowance          @salary_person_setup.temp_money.try(:to_f)
  json.communicate_allowance   @salary_person_setup.communicate_money.try(:to_f)
  json.double_department_check @salary_person_setup.double_department_check
  json.second_department_id    @salary_person_setup.second_department_id
  json.official_car            @salary_person_setup.official_car_money.try(:to_f)
  json.lowest_fly_time         @salary_person_setup.lowest_fly_time
  json.lowest_calc_time        @salary_person_setup.lowest_calc_time
  json.leader_subsidy_time     @salary_person_setup.leader_subsidy_time
  json.fly_check_lifecycle     @salary_person_setup.fly_check_lifecycle

  # 服务B的总工资
  json.base_performance_money @salary_person_setup.base_performance_money.try(:to_f)

  # 保留工资拆分后的字段
  json.keep_position         @salary_person_setup.keep_position.try(:to_f)
  json.keep_performance      @salary_person_setup.keep_performance.try(:to_f)
  json.keep_working_years    @salary_person_setup.keep_working_years.try(:to_f)
  json.keep_minimum_growth   @salary_person_setup.keep_minimum_growth.try(:to_f)
  json.keep_land_allowance   @salary_person_setup.keep_land_allowance.try(:to_f)
  json.keep_life_1           @salary_person_setup.keep_life_1.try(:to_f)
  json.keep_life_2           @salary_person_setup.keep_life_2.try(:to_f)
  json.keep_adjustment_09    @salary_person_setup.keep_adjustment_09.try(:to_f)
  json.keep_bus_14           @salary_person_setup.keep_bus_14.try(:to_f)
  json.keep_communication_14 @salary_person_setup.keep_communication_14.try(:to_f)

  json.second_department do
    json.id            @second_department.id
    json.name          @second_department.full_name
    json.positions     @second_department.positions
    json.grade         @second_department.grade
    json.status        @second_department.status || "active"
    json.serial_number @second_department.serial_number
    json.xdepth        @second_department.depth

    json.parent_id @second_department.parent_id
    json.nature_id @second_department.nature_id
    json.sort_no   @second_department.sort_no
  end if @second_department

  json.airline_attendant_type       @salary_person_setup.airline_attendant_type
  json.join_salary_scal_date        @salary_person_setup.join_salary_scal_date
  json.leader_grade                 @salary_person_setup.leader_grade
  json.lower_limit_hour             @salary_person_setup.lower_limit_hour.try(:to_f)
  json.leader_subsidy_hour          @salary_person_setup.leader_subsidy_hour.try(:to_f)
  json.technical_grade              @salary_person_setup.technical_grade
  json.is_flyer_land_work           @salary_person_setup.is_flyer_land_work
  json.flyer_science_subsidy        @salary_person_setup.flyer_science_subsidy
  json.flyer_science_money          @salary_person_setup.flyer_science_money.try(:to_f)
  json.technical_category           @salary_person_setup.technical_category
  json.performance_position         @salary_person_setup.performance_position
  json.building_subsidy             @salary_person_setup.building_subsidy.try(:to_f)
  json.on_duty_subsidy              @salary_person_setup.on_duty_subsidy.try(:to_f)
  json.retiree_clean_fee            @salary_person_setup.retiree_clean_fee.try(:to_f)
  json.maintain_subsidy             @salary_person_setup.maintain_subsidy.try(:to_f)
  json.part_permit_entry            @salary_person_setup.part_permit_entry
  json.cq_part_time_fix_car_subsidy @salary_person_setup.cq_part_time_fix_car_subsidy
  json.watch_subsidy                @salary_person_setup.watch_subsidy
  json.logistical_support_subsidy   @salary_person_setup.logistical_support_subsidy
  json.flyer_student_train          @salary_person_setup.flyer_student_train
  json.is_send_flyer_science        @salary_person_setup.is_send_flyer_science
  json.is_send_airline_fee          @salary_person_setup.is_send_airline_fee
  json.is_send_transport_fee        @salary_person_setup.is_send_transport_fee
end
