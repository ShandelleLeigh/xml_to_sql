################################################################################
# Assumptions:
  # Only going to use swserverservice application, and skip all others.
    # ( becaue I don't know how to add/delete application and it seems pointless
    #   since they use the same database and version. )
  # Will check all attributes of columns, and if attrs !=, then column will be updated.

################################################################################

require 'nokogiri'
require 'colorize'

@line = ("***"*10)

################################################################################
#     TODO:   # Things to ask before executing rest of file:
################################################################################
puts `clear`
puts @line.light_green
puts "Enter legacy .xml file path: "
old_xml = gets.chomp
puts "Enter newer .xml file path: "
new_xml = gets.chomp


################################################################################
#        # Opens files and parses with Nokogiri
#        # Then makes lists of Apps, Tables, etc.
################################################################################

#long files:
# new_xml = "UpdatedDCCUSwdataPhysicalSchema.xml"
# old_xml = "LegacyDccuSwDataPhysicalSchema.xml"

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

# this makes a list of apps from both files
comp_app = napp | oapp
# puts comp_app

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

def get_deleted_tables(app)
  old_app = @o_doc.at_css("Application[name='#{app}']")
  new_app = @n_doc.at_css("Application[name='#{app}']")
  old_app_tables = Array.new
  new_app_tables = Array.new
  old_app_tables = get_tables_per_app(@o_doc)
  new_app_tables = get_tables_per_app(@n_doc)

  this_table_string = ''
  deleted_tables = (old_app_tables - new_app_tables)

  deleted_tables.each do |table|
    this_table_string += "\nDROP TABLE IF EXISTS #{table};"
  end

  puts this_table_string.red
  return this_table_string
end

################################################################################
#         # Function to get columns for input table from old file
################################################################################

def get_old_columns(n_table, old_cols)
  this_table = @o_doc.at_css("Table[name='#{n_table}']")
  this_table.css("Column").each do |column|
    name = column.attribute("name").value
    old_cols << name
  end
  return old_cols
end

################################################################################
#         # Declare strings
################################################################################
pretty_string = ''

t_s = 'table string'
c_s = 'column string'

t_create = 'CREATE TABLE IF NOT EXISTS'
t_modify = 'MODIFY '
t_delete = 'DELETE '
c_create = 'CREATE '
c_modify = 'MODIFY '
c_delete = 'DELETE '

######################################################################
###---   Gets each attribute and outputs proper string fro Sql
######################################################################
#  @attrib = ''  @attrib_array = [undefined, undefined, undefined, undefined, undefined] <-- this needs to be stated right before this function is called.

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
      end ## Check how to write if statement.....
      @array[4] = attrib
    when 'primarykey'
      attribute.value == 'yes' ?  attrib = 'PRIMARY KEY' : attrib = 'NULL'
      @array[5] = attrib
    when 'unsigned'
      if attribute.value == 'yes' then  attrib = 'UNSIGNED ' end
      @array << attrib
    else
      puts "From line 107"+" WARNING".red + " For column #{name} > #{attribute}=#{attribute.value} won't be set properly in SQL command.  Column '#{name}' hasn't been assiged a case yet. " + "*** ".red
  end
 end

################################################################################
#         # Function to output string for a column including the attributes
################################################################################
def create_col_string(file, table_name, column_name)
  # puts table_name, column_name.blue
  this_col = file.at_css("Table[name='#{table_name}']"&&"Column[name='#{column_name}']")
  @array = ['', '', '', 'NULL ', 'NULL ', '']
  this_col.attributes.each do |name, attribute|
    string = string_case(name, attribute)
  end
  if (@array[5] == "PRIMARY KEY") || (@array[5] != "NULL") then @array[4] = "NOT NULL " end
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
  end #end of each col do:
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

@n_doc.css("Application").each do |application|
  app_name = application.attribute("name").value
  database = application.css("Database").attribute("name").value
  if napp.include?(application) && !oapp.include?(application) #string for create new app
    @alert_string += "A new app: '#{app_name}' was created in the #{database} database. "
  elsif oapp.include?(application) && !napp.include?(application)
    @alert_string += "The app called '#{app_name}' was deleted from the #{database} database. "
  else #if app is in both new and old doc:
    pretty_string += get_deleted_tables(application)
    application.css("Table").each do |table|
      table_name = table.attribute("name").value
    #  puts "\nChecking #{table_name} now: ___________________________".light_green
      this_table_string = String.new
      if !@old_tables.include?(table_name) then
        #puts "Making string to create #{table_name} table: ".green
        this_table_string = create_table_string(@n_doc, table_name, table)
        #puts "#{this_table_string}".light_blue
      # TODO: elsif --TODO: table was deleted? -- not in this function.
      elsif @old_tables.include?(table_name) then
        #puts "#{table_name} exists, checking columns...".cyan
        this_table_string = ""
        old_cols = Array.new
        old_cols = get_old_columns(table_name, old_cols) #gets columns for this table in old document
        #puts "old cols array: #{old_cols}".light_cyan
        table.css("Column").each do |column|
          this_col_string = String.new
          @column_hash = Hash.new #make new hash for "get attributes of columns" function
          column_name = column.attribute("name").value
#-----↓-----↓-----↓-----↓-----↓-----↓-----↓-----↓-----↓-----↓-----↓-----↓------#
          if !old_cols.include?(column_name) # new column was added
            this_col_string = "ADD COLUMN " + create_col_string(@n_doc, table_name, column_name)
            old_cols.delete(column_name)
          elsif old_cols.include?(column_name) # if both have column of same name
            old_column_attribs = create_col_string(@o_doc, table_name, column_name)
            new_column_attribs = create_col_string(@n_doc, table_name, column_name)
#-----↓-----↓-----↓-----↓-----↓-----↓
            if new_column_attribs != old_column_attribs
              this_col_string = "MODIFY COLUMN IF EXISTS #{new_column_attribs}"
              #puts "modify #{column_name} with:...".yellow + this_col_string.light_green
            end
            old_cols.delete(column_name)
          else
            #puts "Something went wrong with #{old_cols} and #{column_name}".red
          end
          this_table_string = mod_alter_table_string(this_table_string, table_name, this_col_string)
        end
        old_cols.each do |i|
          this_col_string = "DELETE COLUMN #{i}"
          this_table_string = mod_alter_table_string(this_table_string, table_name, this_col_string)
        end
        if old_cols.any? then #puts "A delete column thing here for column(s): #{old_cols}".light_red
        end
        # puts "which makes string: ".red
        if this_table_string != '' then #puts this_table_string.light_red
        end
      else
        @error_msg += " Something went wrong when comparing #{table_name} from new file with old file. "
      end
      # puts "this table string so far:....\n#{this_table_string}".light_magenta
      if this_table_string != '' then
        if pretty_string != '' && pretty_string.end_with?("\n") then
          pretty_string += this_table_string + "\n);\n"
        elsif pretty_string != ''
          pretty_string += "\n" + this_table_string + "\n);\n"
        else
          pretty_string += this_table_string + "\n);\n"
        end
      end
      # print "\r", @string_count
      @string_count += 1
      completed_percentage = 0
      completed_percentage = ((@string_count.to_f / @new_table_count.to_f)*100).ceil
      print "\r     #{completed_percentage.round} % done. Loading"+("."*(completed_percentage/2)) +(" " * (50-(completed_percentage/2)))+"|"
    end
  end
end

# pretty_string += @string_create
puts "***".light_green, pretty_string, "***".light_green
# puts "***".light_magenta, @alert_string, "***".light_magenta
# puts "***".red, @error_msg, "***".red


##puts pretty_string and error message:
# puts @line.cyan, pretty_string.green, @error_msg.red, @line.blue

# app_index = 0
#
# def check_empty(val)
#   if (val) == ''
#     val = 'unnamed'
#     return val
#   end
# end
#
# @n_doc.css("Application").each do |application|
#   app_index.to_i
#   @nval = application.attribute("name").value
#   @oval = @o_doc.css("Application")[app_index].attribute("name").value
#
#   if @nval != @oval then
#     #check if oval even exists?
#     if @o_doc.at_css("Application")[app_index].attribute("name").value(@nval)
#
#
#   check_empty(@nval)
#   check_empty(@oval)
#
#
#
#   application.css("Table").each do |table|
#     table.css("Column").each do |column|
#       column.attributes.each do |name, attribute|
#       end #end of attribs
#     end #end of column
#   end #end of table
#   app_index+=1
# end #end of app

# @nval = application.attribute("name").value
# val = @o_doc.css("Application").attribute("name").value
