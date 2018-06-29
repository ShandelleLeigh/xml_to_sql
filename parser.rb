require 'nokogiri'
require 'colorize'

puts `clear`
print ("*"*50 + "\n").light_blue
print ("*"*50 + "\n").light_green
print ("*"*50 + "\n").light_magenta

@new_xml = "UpdatedDCCUSwdataPhysicalSchema.xml"
@old_xml = "LegacyDccuSwDataPhysicalSchema.xml"

@n_doc = Nokogiri::XML(File.open("#{@new_xml}"))
@o_doc = Nokogiri::XML(File.open("#{@old_xml}"))

@new_tables = Array.new
@old_tables = Array.new

@n_doc.css("Table").each do |table|
  @name = table.attribute("name").value
  @new_tables << @name
  # p @new_tables
end

@o_doc.css("Table").each do |table|
  @name = table.attribute("name").value
  @old_tables << @name
  # p @old_tables
end

a_added_tables = Array.new
same = 0
added_tables = 0
i = 0
x = 0
until i == @new_tables.length do
  x +=1
  if !@old_tables.include?(@new_tables[i]) then
    a_added_tables << @new_tables[i]
    added_tables +=1
  else
    same += 1
  end
  i +=1
end


a_removed_tables = Array.new
same = 0
removed_tables = 0
i = 0
x = 0
until i == @old_tables.length do
  x +=1
  if !@new_tables.include?(@old_tables[i]) then
    a_removed_tables << @old_tables[i]
    removed_tables +=1
  else
    same += 1
  end
  i +=1
end

######################################################################

def string_case(name)
  attribs = ''
  case name
  when 'name'
    attrib = attribute.value
  when 'sqltype
    'attribute.value == 'INTEGER' ? attrib = 'INT' : attrib = attribute.value
    #if sqltype == "varchar", no space is needed after this attrib
    return attrib #returns either INT or VARCHAR
  when 'size'
    attrib = "(#{attribute.value}) "
    return attrib #returns something like: (64), which is the size specification for VARCHAR
  when 'primarykey'
    attribute.value == 'yes' ?  attrib = 'PRIMARY KEY' : attrib = 'NULL'
    return attrib
  when 'auto_increment'
    attrib = "IDENTITY(1,1) "
    return attrib
  when 'nullable'
    if attribute.value == 'yes' then attrib = 'NULL DEFAULT NULL' ## Check how to write if statement.....
  else
  end

end


######################################################################
##############   work out logic:
# get names of whole tables added/removed.
# for each table added, get names and attributes of each column, make into string.
  # change types to match sql, and make commands to match action
# for each table on unchaged list, search through columns for changed names/attributes, added/removed cols, and make into sql commands,
######################################################################
a_added_tables.each do |i|
  puts i.light_cyan
end

@tables = ''
count = 0

a_added_tables.each do |table|
  string = "CREATE TABLE " + table + " (\n  "
  this_table = @n_doc.xpath("//Table[@name='#{table}']")
  child = ''
  col_name = ''
  this_table.css("Column").each do |column|
    column.attributes.each do |name, attribute|


      child += name + "=" + attribute.value + " "
    end
    child = child.chomp(" ") + ",\n  "
  end
  this_string = string + child
  # p this_string
  count += 1
  @tables += this_string.chomp(", ") + ");\n"
  # print @tables

end
  puts "count = #{count} \n".magenta + @tables
######################################################################


### Shows which tables were added or dropped:
puts "There were #{added_tables} table(s) added: ".light_green
puts a_added_tables
puts "There were #{removed_tables} table(s) removed: ".red
puts a_removed_tables
