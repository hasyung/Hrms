backup_subsidy = salary.building_subsidy.to_f + salary.property_subsidy.to_f + salary.on_duty_subsidy.to_f + salary.import_on_duty_subsidy.to_f + salary.retiree_clean_fee.to_f + salary.with_parking_subsidy.to_f

json.category 'allowance'
json.id              salary.id
json.employee_id     salary.employee_id
json.employee_no     salary.employee_no
json.employee_name   salary.employee_name
json.department_name salary.department_name
json.position_name   salary.position_name
json.channel_id      salary.channel_id
json.remark          salary.remark
json.notes           salary.notes
json.month           salary.month

json.security_check       format("%.2f", salary.security_check || 0)
json.resettlement         format("%.2f", salary.resettlement || 0)
json.group_leader         format("%.2f", salary.group_leader || 0)
json.air_station_manage   format("%.2f", salary.air_station_manage || 0)
json.car_present          format("%.2f", salary.car_present || 0)
json.land_present         format("%.2f", salary.land_present || 0)
json.permit_entry         format("%.2f", salary.permit_entry || 0)
json.try_drive            format("%.2f", salary.try_drive || 0)
json.fly_honor            format("%.2f", salary.fly_honor || 0)
json.airline_practice     format("%.2f", salary.airline_practice || 0)
json.follow_plane         format("%.2f", salary.follow_plane || 0)
json.permit_sign          format("%.2f", salary.permit_sign || 0)
json.work_overtime        format("%.2f", salary.work_overtime || 0)
json.temp                 format("%.2f", salary.temp || 0)
json.cold                 format("%.2f", salary.cold || 0)
json.communication        format("%.2f", salary.communication || 0)
json.add_garnishee        format("%.2f", salary.add_garnishee || 0)
json.flyer_science_money  format("%.2f", salary.flyer_science_money || 0)
json.backup_subsidy       format("%.2f", backup_subsidy || 0)
json.maintain_subsidy     format("%.2f", salary.maintain_subsidy || 0)
json.annual_audit_subsidy format("%.2f", salary.annual_audit_subsidy || 0)
json.cq_part_time_fix_car_subsidy format("%.2f", salary.cq_part_time_fix_car_subsidy || 0)
json.part_permit_entry format("%.2f", salary.part_permit_entry || 0)
json.watch_subsidy format("%.2f", salary.watch_subsidy || 0)
json.logistical_support_subsidy format("%.2f", salary.logistical_support_subsidy || 0)
json.material_handling_subsidy format("%.2f", salary.material_handling_subsidy || 0)

