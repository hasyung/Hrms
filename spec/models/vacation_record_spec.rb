require 'rails_helper'

RSpec.describe VacationRecord, type: :model do
  before(:each) do
    @employee = create(:employee)
  end

  describe "fix update" do
    context "with 1-1" do
      it "should update over years" do
        @employee.update(join_scal_date: Time.parse("2014-1-1"))
        VacationRecord.update_over_year_days("2015")
        @record = VacationRecord.first
        expect(@record).to be_nil

        @employee.update(join_scal_date: Time.parse("2013-12-31"))
        VacationRecord.update_over_year_days("2015")
        @record = VacationRecord.first
        expect(@record.year).to eq("2015")
        expect(@record.days).to eq(5)
      end

      it "should update less years" do
        @employee.update(join_scal_date: Time.parse("2014-7-1"))
        VacationRecord.update_less_year_days(Time.parse("2014-1-1"), Time.parse("2014-6-30"), "2015")
        @record = VacationRecord.first
        expect(@record).to be_nil

        @employee.update(join_scal_date: Time.parse("2014-1-1"))
        VacationRecord.update_less_year_days(Time.parse("2014-1-1"), Time.parse("2014-6-30"), "2015")
        @record = VacationRecord.first
        expect(@record.year).to eq("2015")
        expect(@record.days).to eq(5)
      end
    end

    context "with 7-1" do
      describe "should fix year days" do
        context "with days > 0" do
          it "should clear days" do
            create(:vacation_record, days: 5, year: "2014", employee_id: @employee.id)
            create(:vacation_record, days: 5, year: "2015", employee_id: @employee.id)

            VacationRecord.fix_year_days("2014", "2015")
            @record = VacationRecord.first
            expect(@record.days).to eq(5)
            expect(VacationRecord.count).to eq(1)
          end
        end

        context "with days < 0" do
          it "should fix current year days" do
            create(:vacation_record, days: -5, year: "2014", employee_id: @employee.id)
            create(:vacation_record, days: 8, year: "2015", employee_id: @employee.id)

            VacationRecord.fix_year_days("2014", "2015")
            @record = VacationRecord.first
            expect(@record.days).to eq(-5 + 8)
            expect(VacationRecord.count).to eq(1)
          end
        end
      end

      it "should update less years" do
        @employee.update(join_scal_date: Time.parse("2014-7-1"))
        VacationRecord.update_less_year_days(Time.parse("2014-1-1"), Time.parse("2014-6-30"), "2015")
        @record = VacationRecord.first
        expect(@record).to be_nil

        @employee.update(join_scal_date: Time.parse("2014-1-1"))
        VacationRecord.update_less_year_days(Time.parse("2014-1-1"), Time.parse("2014-6-30"), "2015")
        @record = VacationRecord.first
        expect(@record.year).to eq("2015")
        expect(@record.days).to eq(5)
      end
    end
  end

  describe "get_year_days" do
    context "with 0-10" do
      it "should works" do
        expect(VacationRecord.send(:get_year_days, 0)).to eq(5)
        expect(VacationRecord.send(:get_year_days, 8)).to eq(5)
      end
    end

    context "with 10-20" do
      it "should works" do
        expect(VacationRecord.send(:get_year_days, 10)).to eq(10)
        expect(VacationRecord.send(:get_year_days, 12)).to eq(10)
      end
    end

    context "with more 20" do
      it "should works" do
        expect(VacationRecord.send(:get_year_days, 20)).to eq(15)
        expect(VacationRecord.send(:get_year_days, 30)).to eq(15)
      end
    end
  end

  describe "reduce days" do
    it "should reduce days" do
      create(:vacation_record, days: 10, year: "2015", employee_id: @employee.id)
      VacationRecord.reduce_days(@employee.id, "2015", 5)
      @record = VacationRecord.first
      expect(@record.days).to eq(5)
    end
  end

  describe "total days" do
    it "should got total days" do
      create(:vacation_record, days: 4, year: "2014", employee_id: @employee.id)
      create(:vacation_record, days: -5, year: "2015", employee_id: @employee.id)
      expect(VacationRecord.year_days(@employee.id)).to eq({year: {"2014" => 4, "2015" => -5}, total: -1})
    end
  end

  describe "total days" do
    it "should got total days" do
      create(:vacation_record, days: 4, year: "2014", employee_id: @employee.id)
      create(:vacation_record, days: -5, year: "2015", employee_id: @employee.id)
      expect(VacationRecord.total_days(@employee.id)).to eq(-1)
    end
  end

  describe "enable vacation" do
    it "should list" do
      create(:vacation_record, days: 4, year: "2014", employee_id: @employee.id)
      create(:vacation_record, days: -5, year: "2015", employee_id: @employee.id)
      #puts VacationRecord.enable_vacation(@employee.id)
      #puts @employee.vacation_summary
      hash = {:enable_vacation=>["事假", "病假", "病假(工伤待定)", "婚假", "丧假", "派驻人员休假", "公假", "探亲假",],
              :year_days=>{:year=>{"2014"=>4, "2015"=>-5}, :total=>-1},
              :scal_working_years=>20, :start_working_years=>40, :is_air_duty => false}
      expect(@employee.vacation_summary).to eq(hash)
    end
  end

  describe "cals days" do
    it "should calc result" do
      Holiday.create(record_date: "2015-05-01", flag: 2)
      Holiday.create(record_date: "2015-06-01", flag: 2)
      condition = {start_date: Date.parse("2015-05-01"),
                   end_date: Date.parse("2015-06-01"),
                   vacation_type: "年假",
                   start_time: Time.parse("2015-05-01T13:30:00.000+08:00"),
                   end_time: Time.parse("2015-06-01T13:30:00.000+08:00"),
                   employee_id: @employee.id}
      hash =  VacationRecord.cals_days(condition)
      expect(hash[:original_total_days]).to eq(32)
      expect(hash[:working_days]).to eq(29)
      expect(hash[:vacation_days]).to eq(29)
    end
  end

  describe "force reduce days" do
    it "should force reduce days" do
      @employee.update(join_scal_date: "2001-01-01")
      create(:vacation_record, days: 5, year: "2015", employee_id: @employee.id)
      VacationRecord.force_reduce_days(@employee.id)
      @record = VacationRecord.first
      expect(@record.days).to eq(5 - 10)
    end
  end

  describe "restore reduce days" do
    it "should restore reduce days" do
      @employee.update(join_scal_date: "2001-01-01")
      create(:vacation_record, days: 5, year: "2015", employee_id: @employee.id)
      VacationRecord.restore_reduce_days(@employee.id)
      @record = VacationRecord.first
      expect(@record.days).to eq(5 + 10)
    end
  end
end
