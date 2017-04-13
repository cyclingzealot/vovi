#!/usr/bin/ruby -w

require 'nokogiri'
require 'open-uri'
require 'uri'
require 'byebug'
require 'getoptlong'
#require 'rubygems'
require 'json'

require_relative './config.rb'

if ARGV[1].nil? then
    $stderr.puts "Need:\n- the price of the home\n- The address"
    puts ARGV
    exit 1
end

amount=ARGV[0].gsub(/[\s,]/ ,"")

url="http://ottawa.ca/cgi-bin/tax/tax.pl?year=24&property_type=110&tr=1&f=8&sw=5&assessment=#{amount}&submit=Submit+Query&lang=en"

puts url

doc = Nokogiri::HTML(open(url))

taxes = doc.xpath("//tr[@class='taxResults']//td")[1].text.gsub(/[\s,]|\$/ ,"").to_f


gmapsUrlBase="https://maps.googleapis.com/maps/api/distancematrix/json?"

$destinations.each { |dest,coords|

    modeHash = {}

    ['walking', 'bicycling', 'transit'].each { |mode|
        url = gmapsUrlBase + "origins=" + ARGV[1].tr(' ', '+') + "&destinations=" + coords.tr(' ', '+') + "&mode=#{mode}" + "&key=" + $apiKey
        resultsHash =  JSON.parse(open(url).read)


        commuteTime = resultsHash['rows'][0]['elements'][0]['duration']['text']

        modeHash[mode] = commuteTime

        debugger if mode == 'cycling'
    }

    puts "#{dest}: #{modeHash.to_s}"

}






# Output results
puts "Estimated annual taxes: #{taxes} $"

