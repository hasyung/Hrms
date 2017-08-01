class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.string :pinyin_name
      t.string :pinyin_index
      t.string :name
      t.string :employee_no #员工编号
      t.string :identity_no #身份证号
      t.string :birth_place #出生地
      t.string :native_place #籍贯

      t.integer :gender_id  #性别
      t.integer :nation_id #民族(码表)
      t.integer :political_status_id #政治面貌(码表)
      t.integer :english_level_id #英语等级(码表)
      t.integer :marital_status_id #婚姻状况(码表)
      t.integer :duty_rank_id #职务职级（码表）

      t.integer :job_title_id #职称(码表)
      t.integer :job_title_degree_id #职称级别(码表)
      t.integer :category_id #分类
      t.integer :location_id #属地化
      t.integer :channel_id  #通道
      t.integer :labor_relation_id  #劳资关系/用工性质

      t.integer :education_background_id #学历
      t.integer :degree_id #学位
      t.string  :school #毕业院校
      t.string  :major #专业

      t.date :birthday  #出生日期
      t.date :start_work_date #参加工作时间
      t.date   :join_scal_date #进入公司时间
      t.string :bit_value, default: '0'
      t.string :flow_bit_value, default: '0'
      t.string :last_login_ip
      t.time :last_login_at
      t.string :crypted_password

      t.string  :favicon
      t.string  :favicon_type
      t.integer :favicon_size,     default: 0

      t.index :bit_value  #权限值
      t.index :flow_bit_value  #流程权限值


      t.integer :employment_status_id #用工状态

      t.timestamps null: false
    end
  end
end
