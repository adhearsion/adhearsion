require 'rubygems'

data  = "13j111ay37"
# cs = 0
# pe = cs + data.length 

%%{
  machine foo;
  write data;
  
  main := [0-9]+ %{ puts "FIRST" } "jay" %{puts 'SECOND'} [0-9]+ %{puts 'THIRD'};
  
  write init;
  write exec;
  write eof;
  
}%%

