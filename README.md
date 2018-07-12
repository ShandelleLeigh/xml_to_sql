# xml_to_sql
Ruby script that compares two XML documents and outputs a SQL command spacifically for MariaDB to make updates to database.

It outputs both a human readable string and an uglier string that might be easier for some programs.

The file itself needs to be modified to open the proper files. 

Uses 'Nokogiri' to parse XML and 'Colorize' for fun. 
