#!/usr/bin/ruby

aptFilePath=ARGV[0]

text=File.open(aptFilePath).read

text.each_line{ |line|
    price, beds, id, long, lat = line.split(' ')

    puts line.strip + ' ' + ((price.to_i)/([beds.to_i,1].max)).round(2).to_s
}
