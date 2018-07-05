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

###Get tables from each file:
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
## Function to get columns for input table from old file
@old_cols = Array.new
def get_old_columns(n_table)

  this_table = @o_doc.at_css("Table[name='#{n_table}']")
  this_table.css("Column").each do |column|
    name = column.attribute("name").value
    # print "***".light_blue + "***".light_cyan+ "***".light_blue, "old table named: ", name, "***".light_blue+"***".light_cyan+"***".light_blue+"\n"

    return @old_cols << name

  end
end


def get_attributes(file, old_table, old_column)

  this_col = file.at_css("Table[name='#{old_table}']"&&"Column[name='#{old_column}']")
  # p column
  this_col.attributes.each do |name, attribute|
    # hash = Hash.new
    # hash[name] = attribute.value
    @column_hash = @column_hash.merge!("#{name}" => "#{attribute.value}")
    # print "\n**".green, name, " ", attribute.value, "**".green

  end #end of old attribs
  return @column_hash
end


###Compare both files:


@string = ' '
@error_msg = ' '

@n_doc.css("Application").each do |application|
  atters_count = 0
  if napp.include?(application) && !oapp.include?(application) #string for create new app
    @string += "Create new app '#{apps}'  "
    #get all of contents from new app
  else #if app is in both new and old doc:
    application.css("Table").each do |table|
      table_name = table.attribute("name").value
      # puts "\n***".yellow,table_name,"***".yellow

      if !@old_tables.include?(table_name) then
        @string += "\nCreate new table: #{table_name}  "
      elsif @old_tables.include?(table_name) then
        old_cols = get_old_columns(table_name) #gets columns for this table in old document
        # puts "#{table_name}".green

        table.css("Column").each do |column|
          @column_hash = Hash.new #make new hash for "get attributes of columns" function
          column_name = column.attribute("name").value

          if !old_cols.include?(column_name) # new column was added
            #TODO: make good string to create this column
            @string += "\nin  table #{table_name} Create new column: #{column_name} ".light_green
          elsif old_cols.include?(column_name) # if both have column of same name
            #TODO: check col attributes, if old atters contain and match new atters, [X] get all attributes from old column
            #get attributes from old and new files as a hash:
            old_hash = get_attributes(@o_doc, table_name, column_name)
            new_hash = get_attributes(@n_doc, table_name, column_name)
            #compare atters:
            if (old_hash.size) > (new_hash.size) #if an attrib was deleted TODO: write script for added/deleted attrib
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
          else puts column_name

          end #f !old_cols.include?(column_name)

        end #column
      else
        @error_msg += " Something went wrong when comparing #{table_name} from new file with old file. "
      end #end table if stmnt
    end #each do table
  end #if app stmnt
end #each do app

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
