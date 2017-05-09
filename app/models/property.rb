
require 'nokogiri'
require 'open-uri'
require_relative './../../config.rb'

class Property < ActiveRecord::Base

    def ==(another_property)
        self.address == another_property.address
    end

    def self.slurpData(pathToHtml, city)
        dataPath=pathToHtml

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
                lpStr = tdNodes[dataColumnIndex['lp']]
                bedsStr  = tdNodes[dataColumnIndex['beds']]
                address  = tdNodes[dataColumnIndex['address']]

                if (not lpStr.nil? and not lpStr.text.empty?) and (not bedsStr.nil? and not bedsStr.text.empty?) then
                    beds = bedsStr.text.to_i
                    lp = lpStr.text.gsub(/\D/, '').to_i
                    address = address.text

                    address = address + ', ' + city

                    property = Property.find_by(:address=>address)

                    if property.nil?
                        Property.create! :address=>address, :bedrooms => beds, :lastConfirmed => DateTime.now,
                            :listingPrice => lp
                    else
                        property.update :address=>address, :bedrooms=>beds, :lastConfirmed=>DateTime.now,
                            :listingPrice => lp
                    end


                end
            end
        }

    end


    def self.updateLatLong(limit = 5)
        Property.where(:latitude => nil, :longitude => nil)[0 .. limit].each { |p|

            address = p.address
            unitNumber = address[/#[0-9]*/]

            if not unitNumber.nil?
                address = address.sub(unitNumber, '')
                address = address.sub(' ,', ',')
            end

            doubleAddress = address[/[0-9]*&[0-9]*/]
            if not doubleAddress.nil?
                address = address.sub(doubleAddress, doubleAddress.split('&')[0])
            end

            url="https://maps.googleapis.com/maps/api/geocode/json?key=#{$apiKey}&address=#{address.tr(' ', '+')}"
            resultsHash =  JSON.parse(open(url).read)

            lat  = resultsHash['results'][0]['geometry']['location']['lat'].to_f
            long = resultsHash['results'][0]['geometry']['location']['lng'].to_f

            if($minLat < lat and lat < $maxLat and $minLong < long and long < $maxLong)
                p.update(:latitude=>lat, :longitude=>long)
            else
                $stderr.puts "Invalid lat long for #{address} (#{lat}, #{long}) (#{url})"
            end
            sleep 1
        }

    end


    def averageRent()
        long = self.longitude
        lat  = self.latitude
        results=`cd #{$tifDir}; for tifFile in heatMapTIN.tif heatMapIDW.tif; do  gdallocationinfo -wgs84  $tifFile #{long} #{lat} | grep Value | cut -d ':' -f 2 ; done`

        sumRentPerRoom = 0
        numDataPoints = 0
        results.each_line {|l| sumRentPerRoom += l.strip.to_i; numDataPoints += 1}

        avgRentPerRoom = (sumRentPerRoom / numDataPoints).round(2)
    end


    def rentPerLpRatio()
        rentPerLPRatio = (self.averageRent.to_f * self.bedrooms / self.listingPrice)*100.round(2)
        rentPerLPRatio.round(2).to_f
    end

    def self.bestInvestments()
        Property.all.select{ |p| p.rentPerLpRatio >= 0.7} \
            .sort_by{|p| p.rentPerLpRatio}.reverse \
            .each {|p|
            puts "#{p.address}\t#{p.rentPerLpRatio}\t#{p.listingPrice}\t#{p.bedrooms}"
            }
    end



end
