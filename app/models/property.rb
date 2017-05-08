class Property < ActiveRecord::Base

    def ==(another_property)
        self.address == another_property.address
    end

    def self.slurpData(pathToHtml)
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
end
