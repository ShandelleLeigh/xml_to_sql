###*~------~*######*~------~*######*~------~*######*~------~*#####*~------~*####
###~*######*~------~*######*~------~*######*~------~*######*~------~*######*~---
###*~------~*######*~------~*######*~------~*######*~------~*#####*~------~*####

###################################*~------~*######*~------~*###
####  New Hash, get all data   ####~*######*~------~*######*~---
###################################*~------~*######*~------~*###
require 'nokogiri'
require 'colorize'

new_file = "shorter_new_file.xml"
old_file = "shorter_old_file.xml"
# new_file = "UpdatedDCCUSwdataPhysicalSchema.xml"
# old_file = "LegacyDccuSwDataPhysicalSchema.xml"
schema_version = ''

def getinfo(file)
  @doc = Nokogiri.XML(File.open(file))
  @doc.css("SupportworksSchema").each do |schema|
    schema_version = schema.attribute("version").value
  end
  return schema_version
end
#
# new_info = getinfo(new_file)
# old_info = getinfo(old_file)
# puts new_info, old_info
#


def hashify_this(file)
  @doc = Nokogiri.XML(File.open("#{file}"))
  i = 0
  hash = Hash.new
  @doc.css("Application").each do |application| #gets app info. inc: app name, database, tables,
    app_name = application.attribute("name").value
    database = application.css("Database").attribute("name").value ## gets database of application
    tables = Hash.new
    application.css("Table").each do |table|
      table_name = table.attribute("name").value
      @table_hash = Hash.new
      table.css("Column").each do |column|
        column_name = column.attribute("name").value
        @column_hash = Hash.new
        attrib_hash = Hash.new
        column.attributes.each do |name, attribute|
          attrib_hash[name] = attribute.value
          @column_hash = {"#{column_name}" => attrib_hash}
        end #end of columns
        @table_hash = {"#{table_name}" => @column_hash}
        tables = tables.merge(@table_hash)
      end #end of tables
      hash = hash.merge!(:"app#{i}" => {:app_name => app_name, :database => database, :tables => tables})
    end #end of apps
    i += 1
  end
  return hash
end
puts ("***"*12).light_green
puts hashify_this(old_file)
puts ("***"*12).light_blue
puts hashify_this(new_file)
puts ("***"*12).light_red
# p hash

###*~------~*######*~------~*######*~------~*######*~------~*#####*~------~*####
###~*######*~------~*######*~------~*######*~------~*######*~------~*######*~---
###*~------~*######*~------~*######*~------~*######*~------~*#####*~------~*####
require 'nokogiri'
require 'colorize'

puts `clear`
print ("*"*50 + "\n\n").light_blue

@new_xml = "UpdatedDCCUSwdataPhysicalSchema.xml"
@old_xml = "LegacyDccuSwDataPhysicalSchema.xml"

@n_doc = Nokogiri::XML(File.open("#{@new_xml}"))
@o_doc = Nokogiri::XML(File.open("#{@old_xml}"))

@new_tables = Array.new
@old_tables = Array.new

@n_doc.css("Table").each do |table|
  @name = table.attribute("name").value
  @new_tables << @name
end

@o_doc.css("Table").each do |table|
  @name = table.attribute("name").value
  @old_tables << @name
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

same_tables = Array.new
same = 0
i = 0
x = 0
until i == @old_tables.length do
  x +=1
  if @new_tables.include?(@old_tables[i]) then
    same_tables << @old_tables[i]
    same += 1
  end
  i +=1
end

puts "Both files have #{same} tables in common".cyan
# puts same_tables


######################################################################
###---   Gets each name, attribute and outputs proper string fro MSSql
######################################################################
#  @attrib = ''  @array = [undefined, undefined, undefined, undefined, undefined] <-- this needs to be stated right before this function is called.

def string_case(name, attribute)
  case name
    when 'name'
      attrib = attribute.value + " "
      @array[0] = attrib
    when 'sqltype'
      attribute.value == 'INTEGER' ? attrib = 'INT ' : attrib = attribute.value
      #if sqltype == "varchar", no space is needed after this attrib
      # returns either INT or VARCHAR, VARCHAR is in this case so that it can be set without a space afterwords.
      @array[1] = attrib
    when 'size'
      attrib = "(#{attribute.value}) "
      #returns something like: (64), which is the size specification for VARCHAR
      @array[2] = attrib
    when 'auto_increment'
      attrib = "IDENTITY(1,1) "
      @array[3] = attrib
    when 'nullable'
      if attribute.value == 'yes' then
        attrib = 'NULL DEFAULT '
      end ## Check how to write if statement.....
      @array[4] = attrib
    when 'primarykey'
      attribute.value == 'yes' ?  attrib = 'PRIMARY KEY ' : attrib = 'NULL'
      @array[5] = attrib
    when 'unsigned'
      if attribute.value == 'yes' then  attrib = 'UNSIGNED ' end
      @array << attrib
    else
      puts "From line 107"+" WARNING".red + " For column #{name} > #{attribute}=#{attribute.value} won't be set properly in SQL command.  Column '#{name}' hasn't been assiged a case yet. " + "*** ".red
  end
end

######################################################################
# Added Tables:
######################################################################
@added_tables = ''

a_added_tables.each do |table|
  table_string = "CREATE TABLE " + table + " (\n  "
  this_table = @n_doc.xpath("//Table[@name='#{table}']")
  child = ''
  this_table.css("Column").each do |column|  #For each column get the names and values of each attribute:
    @array = ['', '', '', '', '', '']
    column.attributes.each do |name, attribute|
      @attrib = ''
      string_case(name, attribute)  #call to function.
      child += @attrib
    end #end of attrib.each do

    if (@array[4] == '') || (@array[5] == "PRIMARY KEY") then @array[4] = "NOT NULL " end
    @attrib = @array.join
    table_string += @attrib.chomp(" ") + ",\n  "
  end
  @added_tables += table_string.strip!.chomp!(",") + "\n);\n\n"
end

######################################################################
## Removed tables:
######################################################################

@removed_tables = ''
a_removed_tables.each do |table|
  @removed_tables += "DROP TABLE " + table
end

######################################################################
## Changed Tables

#TODO:  find actual differences.
#so far, this uses same_tables array, and gets entire talbe data from new_file as a string.
######################################################################

@modified_tables = ''
old_tables_array = Array.new
new_tables_array = Array.new

@tables_from_old_file = ''
same_tables.each do |table|
  table_string = "ALTER TABLE " + table + " (\n  "
  this_table = @o_doc.xpath("//Table[@name='#{table}']")
  child = ''
  this_table.css("Column").each do |column|
    @array = ['', '', '', '', '', '']
    column.attributes.each do |name, attribute|  ##TODO:  here-- check if this name/attrib is same in both files.
      @attrib = ''
      string_case(name, attribute)
      child += @attrib
    end

    if (@array[4] == '') || (@array[5] == "PRIMARY KEY") then @array[4] = "NOT NULL " end
    @attrib = @array.join
    table_string += @attrib.chomp(" ") + ",\n  "
  end
  @tables_from_old_file += table_string.strip!.chomp!(",") + "\n);\n\n"
  old_tables_array << @tables_from_old_file
end

@tables_from_new_file = ''
same_tables.each do |table|
  table_string = "ALTER TABLE " + table + " (\n  "
  this_table = @n_doc.xpath("//Table[@name='#{table}']")
  child = ''
  this_table.css("Column").each do |column|
    @array = ['', '', '', '', '', '']
    column.attributes.each do |name, attribute|
      @attrib = ''
      string_case(name, attribute)
      child += @attrib
    end

    if (@array[4] == '') || (@array[5] == "PRIMARY KEY") then @array[4] = "NOT NULL " end
    @attrib = @array.join
    table_string += @attrib.chomp(" ") + ",\n  "
  end
  @tables_from_new_file += table_string.strip!.chomp!(",") + "\n);\n\n"
  new_tables_array << @tables_from_new_file
end

##TODO: this is wrong:  it get's too much info.  (not spacific to what attribs actually changed.
##  it needs to find which columns were added/removed, and which were just altered. )

diff_arr = Array.new
diff_arr = new_tables_array - old_tables_array
# puts diff_arr
puts new_tables_array.length
puts old_tables_array.length
puts diff_arr.length ## this gets whole table, I dont need whole table



######################################################################
# ### Shows which tables were added or dropped:
# puts ("*"*50+"\n").light_green + "There were #{added_tables} table(s) added: ".green
# puts  a_added_tables
# puts ("*"*50+"\n").light_red + "There were #{removed_tables} table(s) removed: ".red
# puts a_removed_tables
# # puts ("*"*50+"\n").light_yellow + "There were #{modified_tables} table(s) modified: ".yellow
# # puts a_modified_tables
#
# puts ("*"*50+"\n").light_cyan
# puts @added_tables.light_green
# puts @removed_tables.light_red
# # puts @rmodified_tables.light_yellow
#
# puts ("*"*50+"\n").light_cyan
