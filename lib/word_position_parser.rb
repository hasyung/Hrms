class WordPositionParser < WordParser
  attr_accessor :position_name

  def initialize(filename)
    self.position_name = File.basename(filename)
    self.position_name = self.position_name.gsub(".docx", "").gsub(".doc", "")
    super
  end

  def position_data
    heading_titles = ["一、岗位标识", "二、工作职责", "三、工作权限", "四、工作联系", "五、任职条件", "六、工作时间"]

    if self.plain_text
      lines = self.plain_text.split(/\n/)  
    else
      raise "load content error"
    end

    key = nil
    str = nil
    hash = {}

    lines.each do |line|
      line = clear_chars(line)

      if heading_titles.include?(line)
        if key.present? && str.present?
          found, key = strip_order(key)
          hash[key] = str
          str = ""
        end

        key = line
      else
        if key.present?
          str = "" if str.nil?
          str += line
        end
      end
    end

    found, key = strip_order(key)
    hash[key] = str if key.present? && str.present?
    optimize(hash)
  end

  def clear_chars(line)
    line = line.strip.gsub("|", "").gsub(" ", "").gsub("\n", "")
    #puts "@@#{line}$$"
    line
  end

  def optimize(hash)
    list_titles = ["岗位标识"]

    hash.each do |key, str|
      if list_titles.include?(key)
        hash[key] = extract_basic(str) if key == "岗位标识"
      else
        result = []
        arrays = str.split(/[； ; 。]/)

        arrays.each do |item|
          found, item = strip_order(item)
          #puts "#{found}---------#{item}"

          if found
            result << item
          else
            if result.size > 0 && result[result.size - 1].include?("业务权限：")
              result[result.size - 1] += "；" + item
            else
              result << item
            end
          end
        end

        hash[key] = result
      end
    end

    hash
  end

  def extract_basic(line)
    items = {}

    line =~ /岗位名称：([\u4e00-\u9fa5]*.*)岗位性质/
    items["岗位名称"] = $1

    line =~ /岗位性质：([\u4e00-\u9fa5]*)所属部门/
    items["岗位性质"] = $1

    line =~ /所属部门：([\u4e00-\u9fa5]*)编写日期/
    items["所属部门"] = $1

    line =~ /编写日期：([0-9_-]+)/
    items["编写日期"] = $1

    items
  end

  def strip_order(line)
    order_chars = ["一、", "二、", "三、", "四、", "五、", "六、"]
    order_chars += ["1、", "2、", "3、", "4、", "5、", "6、", "7、", "8、", "9、"]
    order_chars += ["1．", "2．", "3．", "4．", "5．", "6．", "7．", "8．", "9．"]

    found = false

    order_chars.each do |char|
      found = line.include?("：")
      line = line.gsub(char, "")
    end

    return [found, line]
  end
end
