
require 'nokogiri'
require 'open-uri'
require_relative './../../config.rb'

class Property < ActiveRecord::Base

    def ==(another_property)
        self.address == another_property.address
    end

    def self.slurpData(pathToHtml, city)
        propertiesCreated = 0
        propertiesUpdated  = 0
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
                        propertiesCreated += 1
                    else
                        property.update :address=>address, :bedrooms=>beds, :lastConfirmed=>DateTime.now,
                            :listingPrice => lp
                        propertiesUpdated += 1
                    end


                end
            end
        }

        $stderr.puts "#{propertiesCreated} created, #{propertiesUpdated} updated"

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

            if not resultsHash['results'][0].nil?
                lat  = resultsHash['results'][0]['geometry']['location']['lat'].to_f
                long = resultsHash['results'][0]['geometry']['location']['lng'].to_f
            else
                $stderr.puts "No lat long for #{address}"
                next
            end

            if($minLat < lat and lat < $maxLat and $minLong < long and long < $maxLong)
                p.update(:latitude=>lat, :longitude=>long)
            else
                $stderr.puts "Invalid lat long for #{address} (#{lat}, #{long}) (#{url})"
            end
            sleep 1
        }

    end

    def avgRent
        self.averageRent
    end

    def averageRent()
        long = self.longitude
        lat  = self.latitude

        if not lat.nil? and not long.nil?
            results=`cd #{$tifDir}; for tifFile in heatMapTIN.tif heatMapIDW.tif; do  gdallocationinfo -wgs84  $tifFile #{long} #{lat} | grep Value | cut -d ':' -f 2 ; done`

            sumRentPerRoom = 0
            numDataPoints = 0
            results.each_line {|l| sumRentPerRoom += l.strip.to_i; numDataPoints += 1}

            avgRentPerRoom = (sumRentPerRoom / numDataPoints).round(2)
        else
            0
        end
    end


    def rentPerLpRatio()
        rentPerLPRatio = (self.averageRent.to_f * self.bedrooms / self.listingPrice)*100.round(2)
        rentPerLPRatio.round(2).to_f
    end

    def self.bestPotentialInvestments(maxPrice = nil)

        potentialProperties = nil
        if maxPrice.nil?
            potentialProperties = Property.all.select{ |p| p.rentPerLpRatio >= 0.7}
        else
            potentialProperties = Property.all.select{ |p| p.rentPerLpRatio >= 0.7 and p.listingPrice < maxPrice }
        end

        potentialProperties.sort_by{|p| p.rentPerLpRatio}.reverse \
            .each {|p|
                puts p.investStr
            }

    end

    def self.bestCapRates(maxPrice = nil)
        if maxPrice.nil?
            potentialProperties = Properties.all
        else
            potentialProperties = Property.all.select{ |p| p.listingPrice < maxPrice }
        end

        Property.all.sort_by{|p| p.roughCapRate}.reverse[0..20].each {
            puts p.investStr
        }
    end

    def investStr()
        "#{self.address}\t#{self.rentPerLpRatio}\t#{self.listingPrice} $\t#{self.bedrooms} bds\t#{self.averageRent} $/month} %" #\t#{(self.roughCapRate*100).round(1)
    end

    def roughCapRate()
        self.roughMonthlyNOI * 12 / self.listingPrice
    end

    def roughMonthlyNOI()
        self.roughMonthlyGOI - roughMonthlyGOE
    end

    def roughMonthlyGOI
        self.avgRent * 0.95
    end

    def avgAnnualInsurance
        900.to_f
    end

    def roughMonthlyManagement
        self.avgRent.to_f * 0.1
    end

    def roughMonthlyGOE
        self.roughAnnualTaxes/12 + self.avgAnnualInsurance/12 + self.roughAnnualMaintenance/12 + self.roughMonthlyManagement
    end

    def roughAnnualTaxes()
        amount=self.listingPrice
        url="http://ottawa.ca/cgi-bin/tax/tax.pl?year=24&property_type=110&tr=1&f=8&sw=5&assessment=#{amount}&submit=Submit+Query&lang=en"
        doc = Nokogiri::HTML(open(url))
        taxes = doc.xpath("//tr[@class='taxResults']//td")[1].text.gsub(/[\s,]|\$/ ,"").to_f
    end

    def roughAnnualMaintenance
        0.0125 * self.listingPrice
    end




end
