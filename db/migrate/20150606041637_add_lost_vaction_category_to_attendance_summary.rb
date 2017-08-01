class AddLostVactionCategoryToAttendanceSummary < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :annual_leave, :string, default: '0'  # 年假
    add_column :attendance_summaries, :marriage_funeral_leave, :string, default: '0' # 婚丧假
    add_column :attendance_summaries, :prenatal_check_leave, :string, default: '0' # 产前检查假
    add_column :attendance_summaries, :accredit_leave, :string, default: '0' # 派驻人员休假
    add_column :attendance_summaries, :rear_nurse_leave, :string, default: '0' # 生育护理假
    add_column :attendance_summaries, :family_planning_leave, :string, default: '0' # 计划生育假
    add_column :attendance_summaries, :women_leave, :string, default: '0' # 女工假
    add_column :attendance_summaries, :maternity_leave, :string, default: '0' # 产假
    add_column :attendance_summaries, :recuperate_leave, :string, default: '0' # 疗养假
    add_column :attendance_summaries, :injury_leave, :string, default: '0' # 工伤假
    add_column :attendance_summaries, :lactation_leave, :string, default: '0' # 哺乳假

    change_column :attendance_summaries, :paid_leave, :string, default: '0'
    change_column :attendance_summaries, :sick_leave, :string, default: '0'
    change_column :attendance_summaries, :sick_leave_nulliparous, :string, default: '0'
    change_column :attendance_summaries, :sick_leave_injury, :string, default: '0'
    change_column :attendance_summaries, :personal_leave, :string, default: '0'
    change_column :attendance_summaries, :home_leave, :string, default: '0'
    change_column :attendance_summaries, :cultivate, :string, default: '0'
    change_column :attendance_summaries, :evection, :string, default: '0'
    change_column :attendance_summaries, :absenteeism, :string, default: '0'
    change_column :attendance_summaries, :late_or_leave, :string, default: '0'
    change_column :attendance_summaries, :ground, :string, default: '0'
    change_column :attendance_summaries, :surface_work, :string, default: '0'
    change_column :attendance_summaries, :station_days, :string, default: '0'
  end
end
