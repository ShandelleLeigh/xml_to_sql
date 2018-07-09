# monday not working
#
# def create_col_string(file, table_name, column_name)
#   puts table_name, column_name.blue
#   this_col = file.at_css("Table[name='#{table_name}']"&&"Column[name='#{column_name}']")
#   @array = ['', '', '', 'NULL', 'NULL', '']
#   this_col.attributes.each do |name, attribute|
#     string = ''
#   # @attrib_array = [name, int/varchar, incrament, nullable?, is prim key?]
#     string = string_case(name, attribute)
#     # string += @attrib
#     # @column_hash = @column_hash.merge!("#{name}" => "#{attribute.value}")
#   end
#   if (@array[5] == "PRIMARY KEY") then @array[4] = "NOT NULL " end
#       print "***".cyan, "146", @array, "***".cyan
#   string = @array.join
#   string = string.chomp(" ") + ",\n  "
#   print "***".cyan, "146", string, "***".cyan
#   return string #string  ####TODO RETURN STRING NOT HASH
# end

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

#long files:
# new_xml = "UpdatedDCCUSwdataPhysicalSchema.xml"
# old_xml = "LegacyDccuSwDataPhysicalSchema.xml"

# shorter testing files:
new_xml = "shorter_new_file.xml"
old_xml = "empty_old_file.xml"

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

comp_app = napp | oapp
# puts comp_app

################################################################################
#     TODO:   # Things to ask before executing rest of file:
################################################################################

################################################################################
#         # Declare strings
################################################################################
@cmd_s = ''

t_s = 'table string'
c_s = 'column string'

t_create = 'CREATE TABLE IF NOT EXISTS'
t_modify = 'MODIFY '
t_delete = 'DELETE '
c_create = 'CREATE '
c_modify = 'MODIFY '
c_delete = 'DELETE '

str_end = "\n);"


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
#         # Get table names from each file:
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
################################################################################
#         # Function to get columns for input table from old file
################################################################################
@old_cols = Array.new
def get_old_columns(n_table)
  this_table = @o_doc.at_css("Table[name='#{n_table}']")
  this_table.css("Column").each do |column|
    name = column.attribute("name").value
    return @old_cols << name
  end
end

################################################################################
#         # Function to output string for a created column
################################################################################
def create_col_string(file, table_name, column_name)
  puts table_name, column_name.blue
  this_col = file.at_css("Table[name='#{table_name}']"&&"Column[name='#{column_name}']")
  @array = ['', '', '', 'NULL', 'NULL', '']
  this_col.attributes.each do |name, attribute|
    string = ''
  # @attrib_array = [name, int/varchar, incrament, nullable?, is prim key?]
    string = string_case(name, attribute)
    # string += @attrib
    # @column_hash = @column_hash.merge!("#{name}" => "#{attribute.value}")
  end
  if (@array[5] == "PRIMARY KEY") || (@array[5] != "NULL") then @array[4] = "NOT NULL " end
  string = @array.join
  string = string.chomp(" ")
  print "\n*** 168 ".cyan, string, "***".cyan
  return string #string  ####TODO RETURN STRING NOT HASH
end

################################################################################
#         # Function to make string for a created table.
################################################################################
def create_table_string(file, table_name, table)
  this_table_string = ''
  this_table_string += "CREATE TABLE IF NOT EXISTS #{table_name} (\n  "
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
  this_table_string += col_string + "\n);\n"
  # puts "\n****".light_green,  this_table_string, "****".light_green
  return this_table_string
end

################################################################################
#         #
################################################################################



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
# @cmd_s = '' -- already instantiated
@alert_string = ''
@error_msg = ''

@n_doc.css("Application").each do |application|
  atters_count = 0

  app_name = application.attribute("name").value
  database = application.css("Database").attribute("name").value

  if napp.include?(application) && !oapp.include?(application) #string for create new app
    @alert_string += "A new app: '#{app_name}' was created in the #{database} database. "
    #TODO: get all of contents from new app and make better string

  elsif oapp.include?(application) && !napp.include?(application)
    @alert_string += "The app called '#{app_name}' was deleted from the #{database} database. "
    #TODO: is it possible to add/delete app with MS-SQL?

  else #if app is in both new and old doc:
    application.css("Table").each do |table|
      table_name = table.attribute("name").value

      if !@old_tables.include?(table_name) then
        this_string = create_table_string(@n_doc, table_name, table)
        puts "\n****".light_green,  this_string, "****".light_green

      # TODO: elsif --TODO: table was deleted? -- not in this function.
      elsif @old_tables.include?(table_name) then
        old_cols = get_old_columns(table_name) #gets columns for this table in old document
        # puts "#{table_name}".green

        table.css("Column").each do |column|
          this_table_string = ''
          @column_hash = Hash.new #make new hash for "get attributes of columns" function
          column_name = column.attribute("name").value

          if !old_cols.include?(column_name) # new column was added
            #TODO: make good string to create this column
            @cmd_s += "\nin  table #{table_name}".light_green
            string = create_col_string(@n_doc, table_name, column_name)
            # @cmd_s += string
          elsif old_cols.include?(column_name) # if both have column of same name
            #TODO: check col attributes, if old atters contain and match new atters, [X] get all attributes from old column
            #get attributes from old and new files as a hash:
            old_hash = get_attributes(@o_doc, table_name, column_name)
            new_hash = get_attributes(@n_doc, table_name, column_name)
            #compare atters:
            if (old_hash.size) != (new_hash.size)
              #modify column string.

            end #if (old_hash.size) > (new_hash.size)
          else # puts column_name #if column was deleted. TODO

          end #f !old_cols.include?(column_name)

        end #column
      else
        @error_msg += " Something went wrong when comparing #{table_name} from new file with old file. "
      end #end table if stmnt
    end #each do table
  end #if app stmnt
end #each do app

# puts "***".light_green, @cmd_s, "***".light_green
# puts "***".light_magenta, @alert_string, "***".light_magenta
# puts "***".red, @error_msg, "***".red


##puts @cmd_s and error message:
# puts @line.cyan, @cmd_s.green, @error_msg.red, @line.blue

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
