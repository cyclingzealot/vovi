#!/usr/bin/ruby -w

require 'nokogiri'
require 'open-uri'
require 'uri'
require 'byebug'
require 'getoptlong'
#require 'rubygems'
require 'json'

require_relative './config.rb'

if ARGV[2].nil? then
    $stderr.puts "Need:\n- the price of the home\n- The address\n- The bedrooms"
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


# Now for average rent
url="https://maps.googleapis.com/maps/api/geocode/json?key=#{$apiKey}&address=#{ARGV[1].tr(' ', '+')}"
resultsHash =  JSON.parse(open(url).read)

lat  = resultsHash['results'][0]['geometry']['location']['lat'].to_f
long = resultsHash['results'][0]['geometry']['location']['lng'].to_f

results=`cd #{$tifDir}; for tifFile in heatMapTIN.tif heatMapIDW.tif; do  gdallocationinfo -wgs84  $tifFile #{long} #{lat} | grep Value | cut -d ':' -f 2 ; done`

sumRentPerRoom = 0
numDataPoints = 0
results.each_line {|l| sumRentPerRoom += l.strip.to_i; numDataPoints += 1}

avgRentPerRoom = (sumRentPerRoom / numDataPoints).round(2)

puts "Avg rent: #{avgRentPerRoom}, total rent: #{avgRentPerRoom * ARGV[2].to_i}"

rentPerLPRatio = (avgRentPerRoom.to_f * ARGV[2].to_i / ARGV[0].to_i)*100.round(2)


puts "Rent / LP ratio: #{rentPerLPRatio.round(2)}"



# Output results
puts "Estimated annual taxes: #{taxes} $"

