class SocialCardinality < ActiveRecord::Base
  belongs_to :employee

  validates :import_month, :employee_id, presence: true
  validates :import_month, uniqueness: { scope: [:import_month, :employee_id] }

  before_save :set_import_date, if: -> (dep) { dep.import_month_changed? }

  def set_import_date
    self.import_date = self.import_month + "-01"
  end

  class << self
    def check_last_month(import_date)
      Employee.joins(:social_person_setup).where("social_person_setups.social_location not in (?) and
        social_person_setups.temp_cardinality is null", Welfare.get_is_annual_locations).where("employees.id not
        in (select employees.id from employees inner join social_cardinalities on employees.id =
        social_cardinalities.employee_id where social_cardinalities.import_date = '#{import_date}')")
    end

    def compute_cardinality(socials, import_date)
      socials.each do |social|
        limits_arr = get_limits(social)

        sql = []
        limits_arr.each_with_index do |limit, index|
          sql << compute_sql(limit[0], limit[1], Welfare::SOCIAL_TYPES[index])
        end

        SocialCardinality.joins(employee: :social_person_setup)
          .where("social_person_setups.social_location = '#{social["location"]}'")
          .where("import_date = '#{import_date}'").update_all(sql.join(', '))
      end
    end

    def get_limits(social)
      Welfare::SOCIAL_TYPES.inject([]) do |arr, type|
        upper, lower = social[type]['upper_limit'], social[type]['lower_limit']
        upper ||= 0
        lower ||= 0
        arr << [upper, lower]
      end
    end

    def compute_sql(upper, lower, type)
      if(upper == 0 && lower == 0)
        return "social_cardinalities.#{type}_cardinality = 0"
      else
        return "social_cardinalities.#{type}_cardinality = (CASE WHEN ROUND(total, 2) >= #{upper}
            THEN #{upper} WHEN ROUND(total, 2) <= #{lower} THEN #{lower} ELSE ROUND(total, 2) END)"
      end
    end
  end
end
