require "date"
require "json"

module CarRental
    class Car
        attr_accessor :id, :price_per_day, :price_per_km

        def initialize(opts)
            opts.each {|k,v| public_send("#{k}=",v)}
        end
    end

    class Rental
        attr_accessor :id, :car_id, :start_date, :end_date, :distance

        def initialize(opts)
            opts.each {|k,v| public_send("#{k}=",v)}
        end
    end

    def self.calculate_fares
        load_data

        price_rentals = []
        rentals.each do |r|
            end_date = Date.parse r.end_date
            start_date = Date.parse r.start_date

            rental_days = (end_date - start_date + 1).to_i

            car = cars.find { |c| c.id == r.car_id } 
            price_time = calculate_price_per_days(rental_days, car.price_per_day)
            price_km = r.distance * car.price_per_km

            total_price = price_time + price_km

            price_rentals << {
                id: r.id,
                price: total_price.to_i
            }
        end

        write_output({"rentals": price_rentals})
    end

    def self.calculate_price_per_days(rental_days, price_per_day)
        price = 0

        (1..rental_days).each do |day|
            if day == 1
                price += price_per_day
            elsif day >= 2 && day <= 4
                price += (price_per_day * 0.9).to_i
            elsif day >= 5 && day <= 10
                price += (price_per_day * 0.7).to_i
            elsif day > 10
                price += (price_per_day * 0.5).to_i
            end
        end

        price
    end

    def self.load_data
        file = File.open "./data/input.json"
        @data = JSON.load file
    end

    def self.cars
        cars = @data['cars'].map do |c|
            Car.new(c)
        end
    end

    def self.rentals
        rentals = @data['rentals'].map do |r|
            Rental.new(r)
        end
    end

    def self.write_output(result)
        File.open("./data/output.json", "w") do |f|
            f.write(JSON.pretty_generate(result))
        end
    end

    def self.test
        result =  JSON.load File.open "./data/output.json"
        expected =  JSON.load File.open "./data/expected_output.json"

        result == expected
    end
end


CarRental.calculate_fares

pp "Result and Expected Output are the same? " + (CarRental.test ? 'Yes':'No')