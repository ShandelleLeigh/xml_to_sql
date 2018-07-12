################################################################################
# Assumptions:
#   - Just going to output Create/alter/delete tables
#     and ignore if there's >1 <Aplication> tag
#   - Will check all attributes of columns, and if attrs !=, then column will be
#     updated.
#   - If a column doesn't explicitly say it's nullable, this script will make it
#     not nullable.
################################################################################
require 'nokogiri'
require 'colorize'
################################################################################
#        # Things to ask before executing rest of file:
################################################################################
@line = ("*****"*20)
puts @line.light_red,@line.light_magenta,@line.light_blue

# TODO: (un)comment if script should have files hardcoded in or ask for them:

# puts `clear`
# puts @line.light_green
# puts "Enter legacy .xml file path: "
# old_xml = gets.chomp
# puts "Enter newer .xml file path: "
# new_xml = gets.chomp

# long files:
new_xml = "UpdatedDCCUSwdataPhysicalSchema.xml"
old_xml = "LegacyDccuSwDataPhysicalSchema.xml"

################################################################################
#        # Opens files and parses with Nokogiri then makes lists of Apps, Tables, etc.
################################################################################

# shorter testing files:
# new_xml = "shorter_new_file.xml"
# old_xml = "shorter_old_file.xml"

@n_doc = Nokogiri::XML(File.open("#{new_xml}"))
@o_doc = Nokogiri::XML(File.open("#{old_xml}"))

napp = Array.new
oapp = Array.new

@n_doc.css("Application").each do |app|
  name = app.attribute("name").value
  napp << name
end

@o_doc.css("Application").each do |app|
  name = app.attribute("name").value
  oapp << name
end

################################################################################
#         # Get table names from each file, as well as deleted tables
################################################################################
@new_tables = Array.new
@old_tables = Array.new

@n_doc.css("Table").each do |table|
  name = table.attribute("name").value
  @new_tables << name
end

@o_doc.css("Table").each do |table|
  name = table.attribute("name").value
  @old_tables << name
end

def get_tables_per_app(app)
  these_tables = Array.new
  app.css("Table").each do |table|
    name = table.attribute("name").value
    these_tables << name
  end
  return these_tables
end

def get_deleted_tables()
  old_app = @o_doc.at_css("Application")
  new_app = @n_doc.at_css("Application")
  old_app_tables = Array.new
  new_app_tables = Array.new
  old_app_tables = get_tables_per_app(@o_doc)
  new_app_tables = get_tables_per_app(@n_doc)
  this_table_string = ''
  deleted_tables = (old_app_tables - new_app_tables)
  deleted_tables.each do |table|
    this_table_string += "\nDROP TABLE IF EXISTS #{table};"
  end
  return this_table_string
end

################################################################################
#         # Function to get columns for input table from old file
################################################################################

def get_old_columns(app, table_name, old_cols )
  table_name = table_name
  old_cols = []
  # print  "table_name: ".light_blue + table_name
  this_table = app.at_css("Table[name='#{table_name}']")
  this_table.css("Column").each do |column|
    name = column.attribute("name").value
    old_cols << name
  end
  return old_cols
end
################################################################################
#         # Make "DELETE COLUMN #{i}" string.
################################################################################
def check_cols(old_cols, i)
  this_col_string = "DELETE COLUMN #{i}"
  this_table_string = mod_alter_table_string(this_table_string, table_name, this_col_string)
  old_cols.delete(column_name)
  return this_table_string
end
################################################################################
#         # Declare strings
################################################################################
pretty_string = ''

######################################################################
###---   Gets each attribute and outputs proper string fro Sql
######################################################################
#  @attrib = ''  @attrib_array = ['', '', '', '', '']
#  ^^ this needs to be stated right before this function is called. ^^
def string_case(name, attribute)
  case name
    when 'name'
      attrib = attribute.value + " "
      @array[0] = attrib
    when 'sqltype'
      attribute.value == 'INTEGER' ? attrib = 'INT ' : attrib = attribute.value
      @array[1] = attrib
    when 'size'
      attrib = "(#{attribute.value}) "
      @array[2] = attrib
    when 'auto_increment'
      attrib = "IDENTITY(1,1) "
      @array[3] = attrib
    when 'nullable'
      if attribute.value == 'yes' then
        attrib = 'NULL DEFAULT '
      else attrib = 'NOT NULL'
      end
      @array[4] = attrib
    when 'primarykey'
      attribute.value == 'yes' ?  attrib = 'PRIMARY KEY' : attrib = 'NULL'
      @array[5] = attrib
    when 'unsigned'
      if attribute.value == 'yes' then  attrib = 'UNSIGNED ' end
      @array << attrib
    else
      puts "From line 146"+" WARNING".red + " For column #{name} > #{attribute}=#{attribute.value} won't be set properly in SQL command.  Column '#{name}' hasn't been assiged a case yet. " + "*** ".red
  end
end

################################################################################
#         # Function to output string for a column including the attributes
################################################################################
def create_col_string(file, table_name, column_name)
  this_col = file.at_css("Table[name='#{table_name}']"&&"Column[name='#{column_name}']")
# @array = [name, INT, (8),incrmnt?, Null Default, Primary key,(unsigned)]
  @array = ['', '', '', '', 'NULL ', 'NULL']
  this_col.attributes.each do |name, attribute|
    string = string_case(name, attribute)
  end
  if (@array[5] == "PRIMARY KEY") || (@array[4] != "NULL DEFAULT ") then @array[4] = "NOT NULL " end
  string = @array.join.chomp(" ")
  return string
end

################################################################################
#         # Function to make string for a created table.
################################################################################
def create_table_string(file, table_name, table)
  this_table_string = ''
  this_table_string += "\nCREATE TABLE IF NOT EXISTS #{table_name} (\n  "
  col_string = ''
  table.css("Column").each do |column|
    @column_hash = Hash.new
    column_name = column.attribute("name").value
    string = create_col_string(@n_doc, table_name, column_name)
    if col_string == '' then
      col_string += string
    else
      col_string += ",\n  " + string
    end
  end
  this_table_string += col_string
  return this_table_string
end

################################################################################
#         #Function to add columns to alter_table_string
################################################################################
def mod_alter_table_string(table_string, table_name, col_string)
  if col_string != '' then
    if table_string == '' then
      table_string += "\nALTER TABLE IF EXISTS #{table_name} ( \n  " + col_string
    else
      table_string += ",\n  " + col_string
    end
  end
  return table_string
end

################################################################################
#         # Get all attributes of column.  Output Hash.
################################################################################
def get_attributes(file, table_name, column_name)
  this_col = file.at_css("Table[name='#{table_name}']"&&"Column[name='#{column_name}']")
  this_col.attributes.each do |name, attribute|
    @column_hash = @column_hash.merge!("#{name}" => "#{attribute.value}")
  end
  return @column_hash
end
################################################################################
#         # Compare both files:
################################################################################
@new_table_count = @new_tables.length
@string_count = 0
@alert_string = ''
@error_msg = ''
@string_create = ''
atters_count = 0
pretty_string += get_deleted_tables()

@n_doc.css("Application").each do |application|
  app_name = application.attribute("name").value
  database = application.css("Database").attribute("name").value
  if napp.include?(application) && !oapp.include?(application) #string for create new app
    @alert_string += "A new app: '#{app_name}' was created in the #{database} database. "
  elsif oapp.include?(application) && !napp.include?(application)
    @alert_string += "The app called '#{app_name}' was deleted from the #{database} database. "
  else #if both app exists in both files, move to TABLES:
    application.css("Table").each do |table|
      table_name = table.attribute("name").value
      this_table_string = String.new
      if !@old_tables.include?(table_name) then #create a table:
        this_table_string = create_table_string(@n_doc, table_name, table)
      elsif @old_tables.include?(table_name) then #both files have this table, move to COLUMNS:
        old_cols = get_old_columns(@o_doc, table_name, old_cols)
        new_cols = get_old_columns(@n_doc, table_name, old_cols)
        table.css("Column").each do |column|
          this_col_string = String.new
          column_name = column.attribute("name").value
          if !old_cols.include?(column_name) # new column was added
            this_col_string = "ADD COLUMN " + create_col_string(@n_doc, table_name, column_name)
          else old_cols.include?(column_name) # if both have column of same name
            old_column_attribs = create_col_string(@o_doc, table_name, column_name)
            new_column_attribs = create_col_string(@n_doc, table_name, column_name)
            if new_column_attribs != old_column_attribs #if attribs dont match, replace with new attribs
              this_col_string = "MODIFY COLUMN IF EXISTS #{new_column_attribs}"
            end
            old_cols = old_cols - [column_name]
          end
          if this_table_string != '' then #puts this_table_string.light_red
          end
          this_table_string = mod_alter_table_string(this_table_string, table_name, this_col_string)
        end
        if old_cols.is_a?(Array)
          old_cols.to_a.each do |i|
            this_col_string = "DELETE COLUMN #{i}"
            this_table_string = mod_alter_table_string(this_table_string, table_name, this_col_string)
          end
        else old_cols.is_a?(String)
          i = column_name
          this_col_string = "DELETE COLUMN #{i}"
          this_table_string = mod_alter_table_string(this_table_string, table_name, this_col_string)
          old_cols = old_cols.delete(column_name)
        end
      else
        @error_msg += " Something went wrong when comparing #{table_name} from new file with old file. ".red
      end
### Formatting pretty_string:
      if this_table_string != '' then
        if pretty_string != '' && pretty_string.end_with?("\n") then
          pretty_string += this_table_string + "\n);\n"
        elsif pretty_string != ''
          pretty_string += "\n" + this_table_string + "\n);\n"
        else
          pretty_string += this_table_string + "\n);\n"
        end
      end
## Loading progress:
      @string_count += 1
      completed_percentage = 0
      completed_percentage = ((@string_count.to_f / @new_table_count.to_f)*100).ceil
      print "\r     #{completed_percentage.round} % done. Loading"+("."*(completed_percentage/2)) +(" " * (50-(completed_percentage/2)))
    end
  end
end

#TODO: if either the ugly or pretty string is unwanted, it can be removed:
# pretty string puts each command on multiple lines, ugly_string puts commands on only one line.
ugly_string = pretty_string.gsub("\n"," ").gsub("  ", "").gsub(";", ";\n")

puts "\n", @line.light_green, pretty_string
puts @line.light_green, ugly_string
