#!/usr/bin/ruby -w

require 'nokogiri'
require 'open-uri'
require 'byebug'

if ARGV[0].nil? then
    $stderr.puts "Need the price of the home"
    puts ARGV
    exit 1
end

amount=ARGV[0].gsub(/[\s,]/ ,"")

url="http://ottawa.ca/cgi-bin/tax/tax.pl?year=24&property_type=110&tr=1&f=8&sw=5&assessment=#{amount}&submit=Submit+Query&lang=en"

puts url

doc = Nokogiri::HTML(open(url))

amount = doc.xpath("//tr[@class='taxResults']//td")[1].text.gsub(/[\s,]|\$/ ,"").to_f

puts "Estimated annual taxes: #{amount} $"

