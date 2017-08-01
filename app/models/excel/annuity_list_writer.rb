require "spreadsheet"

module Excel
  class AnnuityListWriter

    class << self
      def export_annuity_to_xls(records)
        file_name = "#{Time.now.to_i}_年金额记录.xls"
        file_path = "#{Rails.root}/public/export/tmp/#{file_name}"

        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet

        #填写第一行
        [
          "序号*","计算时间","所属企业名称","编码","姓名*","证件类型*",
          "证件号码*","手机号码","基数","企业缴费*","个人缴费*","备注"
        ].each_with_index do |title, index|
          sheet[0, index] = title
        end

        counter = 0
        records.find_each do |item|
          counter = counter + 1
          sheet[counter, 0]  = counter
          sheet[counter, 1]  = item.cal_date
          sheet[counter, 2]  = "四川航空股份有限公司"
          sheet[counter, 3]  = item.employee_no
          sheet[counter, 4]  = item.employee_identity_name
          sheet[counter, 5]  = "身份证"
          sheet[counter, 6]  = item.identity_no
          sheet[counter, 7]  = item.mobile
          sheet[counter, 8]  = item.annuity_cardinality
          sheet[counter, 9]  = item.company_payment
          sheet[counter, 10] = item.personal_payment
          sheet[counter, 11] = item.note
        end

        book.write file_path

        { path: file_path, filename: file_name }
      end
    end

  end
end
