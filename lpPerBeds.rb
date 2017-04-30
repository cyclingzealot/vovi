#!/usr/bin/ruby


require 'nokogiri'
require 'open-uri'
require 'uri'
require 'byebug'
require 'set'
#require 'getoptlong'



dataPath=ARGV[0]

doc = Nokogiri::HTML(open(dataPath))


tbodies = doc.xpath("//tr")

puts tbodies.count

listings = {}

tbodies.each { |tbodyNode|
    tdNodes = tbodyNode.xpath("./td")

    dataColumnIndex = {
        'address'   => 10,
        'lp'        => 11,
        'beds'      => 16,
        'status'    => 8
     }

    if tdNodes.count >= 16+1
        status = tdNodes[dataColumnIndex['status']].text
        if not ['Sold', 'Conditional'].include?(status)
            lpStr = tdNodes[dataColumnIndex['lp']]
            bedsStr  = tdNodes[dataColumnIndex['beds']]
            address  = tdNodes[dataColumnIndex['address']]

            if (not lpStr.nil? and not lpStr.text.empty?) and (not bedsStr.nil? and not bedsStr.text.empty?) then
                beds = bedsStr.text.to_i
                lp = lpStr.text.gsub(/\D/, '').to_i/100
                address = address.text

                #debugger
            
                listings[address] = (lp/beds).round if beds > 0
            end
        end
    end 
}

listings.sort_by {|_key, value| value}.reverse.each {|address, lpPerBeds| puts "#{address} #{lpPerBeds}"}
