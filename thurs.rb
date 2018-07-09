require 'nokogiri'
require 'colorize'

@line = ("***"*10)

new_xml = "UpdatedDCCUSwdataPhysicalSchema.xml"
old_xml = "LegacyDccuSwDataPhysicalSchema.xml"

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
puts comp_app

################################################################################
#         # Things to ask first:  TODO
################################################################################

################################################################################
#         # Declare strings
################################################################################
@cmd_s = ''

t_s = 'table string'
c_s = 'column string'
a_s = 'attrib string'

t_create = 'CREATE '
t_modify = 'MODIFY '
t_delete = 'DELETE '
c_create = 'CREATE '
c_modify = 'MODIFY '
c_delete = 'DELETE '
a_create = 'CREATE '
a_modify = 'MODIFY '
a_delete = 'DELETE '

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
      attribute.value == 'yes' ?  attrib = 'PRIMARY KEY ' : attrib = 'NULL'
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
  this_col = file.at_css("Table[name='#{table_name}']"&&"Column[name='#{column_name}']")
  this_col.attributes.each do |name, attribute|
    string = ' '
  # @attrib_array = [name, int/varchar, incrament, nullable?, is prim key?]
    @array = ['undefined', 'undefined', 'undefined', 'undefined', 'undefined']
    string_case(name, attribute)
    puts @attrib
    # string += @attrib
    # @column_hash = @column_hash.merge!("#{name}" => "#{attribute.value}")
  end
  if (@array[5] == "PRIMARY KEY") then @array[4] = "NOT NULL " end
  # @attrib = @array.join
  # table_string += @attrib.chomp(" ") + ",\n  "
  # return table_string#string  ####TODO RETURN STRING NOT HASH
end

################################################################################
#         # Function to make string for a created table.
################################################################################
def create_table_string(file, table_name)

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
@string = ''
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
        #TODO: make good string for new table created.
        @string += "\nCreate new table: #{table_name}  "
        # ```
        # CREATE TABLE
        #   [ ]
        #   ```

      #elsif --TODO: table was deleted?

      elsif @old_tables.include?(table_name) then
        old_cols = get_old_columns(table_name) #gets columns for this table in old document
        # puts "#{table_name}".green

        table.css("Column").each do |column|
          this_table_string = ''
          @column_hash = Hash.new #make new hash for "get attributes of columns" function
          column_name = column.attribute("name").value

          if !old_cols.include?(column_name) # new column was added
            #TODO: make good string to create this column
            @string += "\nin  table #{table_name}".light_green
            string = create_col_string(@n_doc, table_name, column_name)
            # @string += string
          elsif old_cols.include?(column_name) # if both have column of same name
            #TODO: check col attributes, if old atters contain and match new atters, [X] get all attributes from old column
            #get attributes from old and new files as a hash:
            old_hash = get_attributes(@o_doc, table_name, column_name)
            new_hash = get_attributes(@n_doc, table_name, column_name)
            #compare atters:
            if (old_hash.size) != (new_hash.size) #if an attrib was deleted TODO: write script for added/deleted attrib
              diff = old_hash - new_hash
              puts diff, "line 110".light_green
            elsif (new_hash.size) > (old_hash.size) #if an attrib was added TODO: write script for added/deleted attrib
              diff = new_hash - old_hash
              puts diff, "line 114".light_green
            elsif old_hash == new_hash #if same amount of attrib
              old_s = old_hash.to_s
              new_s = new_hash.to_s
              if old_s == new_s ## then the shared attributes are exactly the same!! hooray, do nothing
                atters_count += 1
              else ## TODO: write a way to update an attribute

              end #if old_s == new_s
            else
            end #if (old_hash.size) > (new_hash.size)
          else puts column_name #if column was deleted. TODO

          end #f !old_cols.include?(column_name)

        end #column
      else
        @error_msg += " Something went wrong when comparing #{table_name} from new file with old file. "
      end #end table if stmnt
    end #each do table
  end #if app stmnt
end #each do app

puts "***".light_green, @string, "***".light_green
puts "***".light_magenta, @alert_string, "***".light_magenta
puts "***".red, @error_msg, "***".red


##puts @string and error message:
# puts @line.cyan, @string.green, @error_msg.red, @line.blue

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
