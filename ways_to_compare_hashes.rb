require 'colorize'

### Different ways to compare Hashes.
#  For comparing attributes of columns,  if colum info != second column info, then it's modified.
#no need to find exactly what's different, just update column with new info.

og = Hash.new
og = {:a => 'apple', :b => 'banana', :c => 'cat'}
modify = Hash.new
modify = {:a => 'apple', :b => 'boy', :c => 'cat'}
shorter= Hash.new
shorter = {:a => 'apple', :b => 'boy'}
longer= Hash.new
longer = {:a => 'apple', :b => 'banana', :c => 'cat', :d => 'dog'}



def comp(first, second)
  puts "***".blue + "***".light_cyan + "***".blue
  puts  "ln 16", first, second
  if (first.size) > (second.size)
    diff = first.to_a - second.to_a
    puts "\n" , "line 19 deleted something: ".light_red, diff
  elsif (second.size) > (first.size)
    diff = second.to_a - first.to_a
    puts "\n" ,"line 22 added something: ".light_green, diff
  elsif first == second
    puts "first == second"
    old_s = first.to_s
    new_s = second.to_s
    if old_s == new_s  #  <---!!!this bit is unnessisary.!!!---->
      puts "first hash is == to second hash, even if to_s"
    else
      puts "21 puts first hash is == to second hash, ebut not if to_s".yellow, first, second
    end #if old_s == new_s
  else puts "23".magenta, first, second
  end
end

comp(og, modify)
comp(og, shorter)
comp(og, longer)
comp(og, og)
