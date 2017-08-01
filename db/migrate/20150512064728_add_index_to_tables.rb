class AddIndexToTables < ActiveRecord::Migration
  def change
    #actions
    add_index :actions, :employee_id

    #attachments
    add_index :attachments, :path
    add_index :attachments, :size
    add_index :attachments, :mimetype

    #authenticate_tokens
    add_index :authenticate_tokens, :token
    add_index :authenticate_tokens, :expire_at
    add_index :authenticate_tokens, :employee_id

    #code_table_categories
    add_index :code_table_categories, :name
    add_index :code_table_categories, :display_name
    add_index :code_table_categories, :key

    #code_table_channels
    add_index :code_table_channels, :name
    add_index :code_table_channels, :display_name

    #code_table_department_grades
    add_index :code_table_department_grades, :level
    add_index :code_table_department_grades, :index
    add_index :code_table_department_grades, :readable_index
    add_index :code_table_department_grades, :display_name

    #code_table_locations
    add_index :code_table_locations, :name
    add_index :code_table_locations, :display_name

    #code_tables
    add_index :code_tables, :name
    add_index :code_tables, :display_name
    add_index :code_tables, :type
    add_index :code_tables, :level

    #department_change_logs
    add_index :department_change_logs, :title
    add_index :department_change_logs, :oa_file_no
    add_index :department_change_logs, :dep_name
    add_index :department_change_logs, :department_id

    #departments
    add_index :departments, :name
    add_index :departments, :pinyin_name
    add_index :departments, :pinyin_index
    add_index :departments, :serial_number
    add_index :departments, :depth
    add_index :departments, :childrens_count
    add_index :departments, :grade_id
    add_index :departments, :nature_id
    add_index :departments, :parent_id
    add_index :departments, :childrens_index
    add_index :departments, :d1_sort_no
    add_index :departments, :d2_sort_no
    add_index :departments, :d3_sort_no

    #employee_contact_ways
    add_index :employee_contact_ways, :telephone
    add_index :employee_contact_ways, :mobile
    add_index :employee_contact_ways, :email
    add_index :employee_contact_ways, :postcode
    add_index :employee_contact_ways, :employee_id

    #employee_duty_ranks
    add_index :employee_duty_ranks, :name
    add_index :employee_duty_ranks, :display_name

    #employee_education_experiences
    add_index :employee_education_experiences, :school
    add_index :employee_education_experiences, :major
    add_index :employee_education_experiences, :admission_date
    add_index :employee_education_experiences, :graduation_date
    add_index :employee_education_experiences, :education_background_id
    add_index :employee_education_experiences, :education_nature_id
    add_index :employee_education_experiences, :degree_id
    add_index :employee_education_experiences, :witness
    add_index :employee_education_experiences, :category
    add_index :employee_education_experiences, :employee_id

    #employee_employment_statuses
    add_index :employee_employment_statuses, :name
    add_index :employee_employment_statuses, :display_name

    #employee_family_members
    add_index :employee_family_members, :name
    add_index :employee_family_members, :native_place
    add_index :employee_family_members, :birthday
    add_index :employee_family_members, :start_work_date
    add_index :employee_family_members, :married_date
    add_index :employee_family_members, :gender
    add_index :employee_family_members, :nation
    add_index :employee_family_members, :position
    add_index :employee_family_members, :company
    add_index :employee_family_members, :mobile
    add_index :employee_family_members, :identity_no
    add_index :employee_family_members, :residence_booklet
    add_index :employee_family_members, :political_status
    add_index :employee_family_members, :education_background
    add_index :employee_family_members, :relation_type
    add_index :employee_family_members, :relation
    add_index :employee_family_members, :employee_id

    #employee_job_title_degrees
    add_index :employee_job_title_degrees, :job_type_id
    add_index :employee_job_title_degrees, :name
    add_index :employee_job_title_degrees, :display_name

    #employee_job_titles
    add_index :employee_job_titles, :job_type_id
    add_index :employee_job_titles, :name
    add_index :employee_job_titles, :display_name

    #employee_job_types
    add_index :employee_job_types, :name
    add_index :employee_job_types, :display_name

    #employee_labor_relations
    add_index :employee_labor_relations, :name
    add_index :employee_labor_relations, :display_name

    #employee_permissions
    add_index :employee_permissions, :employee_id

    #employee_personal_infos
    add_index :employee_personal_infos, :employee_id

    #employee_positions
    add_index :employee_positions, :employee_id
    add_index :employee_positions, :position_id
    add_index :employee_positions, :sort_index
    add_index :employee_positions, :start_date
    add_index :employee_positions, :end_date
    add_index :employee_positions, :remark
    add_index :employee_positions, :category

    #employee_work_experiences
    add_index :employee_work_experiences, :company
    add_index :employee_work_experiences, :department
    add_index :employee_work_experiences, :position
    add_index :employee_work_experiences, :job_title
    add_index :employee_work_experiences, :start_date
    add_index :employee_work_experiences, :end_date
    add_index :employee_work_experiences, :witness
    add_index :employee_work_experiences, :employee_id

    #employees
    add_index :employees, :pinyin_name
    add_index :employees, :pinyin_index
    add_index :employees, :name
    add_index :employees, :employee_no
    add_index :employees, :identity_no
    add_index :employees, :birth_place
    add_index :employees, :native_place
    add_index :employees, :gender_id
    add_index :employees, :nation_id
    add_index :employees, :political_status_id
    add_index :employees, :english_level_id
    add_index :employees, :marital_status_id
    add_index :employees, :duty_rank_id
    add_index :employees, :job_title_id
    add_index :employees, :job_title_degree_id
    add_index :employees, :category_id
    add_index :employees, :location_id
    add_index :employees, :channel_id
    add_index :employees, :labor_relation_id
    add_index :employees, :education_background_id
    add_index :employees, :degree_id
    add_index :employees, :school
    add_index :employees, :major
    add_index :employees, :birthday
    add_index :employees, :start_work_date
    add_index :employees, :join_scal_date
    #add_index :employees, :bit_value
    add_index :employees, :last_login_ip
    add_index :employees, :last_login_at
    add_index :employees, :employment_status_id
    add_index :employees, :updated_at
    add_index :employees, :favicon
    add_index :employees, :favicon_type
    add_index :employees, :favicon_size
    add_index :employees, :sort_no
    add_index :employees, :department_id
    add_index :employees, :position_remark
    add_index :employees, :technical_duty
    add_index :employees, :approve_leave_job_date
    add_index :employees, :leave_job_reason
    add_index :employees, :is_delete
    add_index :employees, :is_virtual
    add_index :employees, :virtual_name

    #flow_attachments
    add_index :flow_attachments, :flow_id
    add_index :flow_attachments, :file
    add_index :flow_attachments, :file_type
    add_index :flow_attachments, :file_size

    #flows
    add_index :flows, :name
    add_index :flows, :sponsor_id
    add_index :flows, :receptor_id
    add_index :flows, :reviewer_ids
    add_index :flows, :type
    add_index :flows, :workflow_state
    add_index :flows, :viewer_ids

    #permissions
    add_index :permissions, :category
    add_index :permissions, :controller
    add_index :permissions, :action
    add_index :permissions, :rw_type
    add_index :permissions, :bit_value
    add_index :permissions, :channel
    add_index :permissions, :channel_value

    #positions
    add_index :positions, :pinyin_name
    add_index :positions, :pinyin_index
    add_index :positions, :name
    add_index :positions, :budgeted_staffing
    add_index :positions, :oa_file_no
    add_index :positions, :post_type
    add_index :positions, :remark
    add_index :positions, :department_id
    add_index :positions, :channel_id
    add_index :positions, :schedule_id
    add_index :positions, :category_id
    add_index :positions, :position_nature_id
    add_index :positions, :employees_count
    add_index :positions, :sort_no

    #primary_keys
    add_index :primary_keys, :model  	
    add_index :primary_keys, :max_id

    #schedules
    add_index :schedules, :name  	
    add_index :schedules, :display_name

    #system_configs
    add_index :system_configs, :key  	
    add_index :system_configs, :value

    #workflow_events
    add_index :workflow_events, :flow_id  	
    add_index :workflow_events, :workflow_state  	
    add_index :workflow_events, :reviewer_id  	
    add_index :workflow_events, :reviewer_no
    add_index :workflow_events, :reviewer_name  	
    add_index :workflow_events, :reviewer_position  	
    add_index :workflow_events, :reviewer_department  	
    add_index :workflow_events, :event  	
    add_index :workflow_events, :parent_id
  end
end
