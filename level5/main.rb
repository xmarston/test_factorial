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
        COMMISSION_RATE = 0.3
        INSURANCE_RATE = 0.5
        ASSISTANCE_PRICE_PER_DAY = 100

        attr_accessor :id, :car_id, :start_date, :end_date, :distance

        def initialize(opts)
            opts.each {|k,v| public_send("#{k}=",v)}
        end

        def calculate_commission(total_price, rental_days)
            commission = total_price * Rental::COMMISSION_RATE
        
            insurance_fee = commission * Rental::INSURANCE_RATE
            assistance_fee = rental_days * Rental::ASSISTANCE_PRICE_PER_DAY
            our_fee = commission - insurance_fee - assistance_fee

            {
                insurance: insurance_fee.to_i,
                assistance: assistance_fee.to_i,
                drivy: our_fee.to_i
            }        
        end
    end

    class Option
        GPS_PRICE_PER_DAY = 500
        BABY_SEAT_PRICE_PER_DAY = 200
        ADDITIONAL_INSURANCE_PRICE_PER_DAY = 1000

        FARES_DAY = {
            gps: GPS_PRICE_PER_DAY,
            baby_seat: BABY_SEAT_PRICE_PER_DAY,
            additional_insurance: ADDITIONAL_INSURANCE_PRICE_PER_DAY
        }

        attr_accessor :id, :rental_id, :type

        def initialize(opts)
            opts.each {|k,v| public_send("#{k}=",v)}
        end

        def calculate(rental_days)
            FARES_DAY[type.to_sym] * rental_days
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
            options_calculated = calculate_options_price(r.id, rental_days)
            total_price += options_calculated.values.sum
            commissions = r.calculate_commission(total_price, rental_days)
            actions = calculate_actions(total_price, commissions, options_calculated)

            price_rentals << {
                id: r.id,
                options: options_calculated.keys,
                actions: actions
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

    def self.calculate_actions(total_price, commissions, opts_price)
        total_commision_amount = commissions.values.sum
        total_opts_price = opts_price.values.sum
     
        gps_price = opts_price.key?(:gps) ? opts_price[:gps] : 0
        baby_seat_price = opts_price.key?(:baby_seat) ? opts_price[:baby_seat] : 0
        additional_insurance_price = opts_price.key?(:additional_insurance) ? opts_price[:additional_insurance] : 0

        owner_credit = (total_price - total_opts_price - total_commision_amount) + gps_price + baby_seat_price
        drivy_credit = commissions[:drivy] + additional_insurance_price
        actions = [
            { who: "driver", type: "debit", amount: total_price.to_i },
            { who: "owner", type: "credit", amount: owner_credit },
            { who: "insurance", type: "credit", amount: commissions[:insurance] },
            { who: "assistance", type: "credit", amount: commissions[:assistance] },
            { who: "drivy", type: "credit", amount: drivy_credit }
        ]

        actions
    end

    def self.calculate_options_price(rental_id, rental_days)
        opts = options.select { |o| o.rental_id == rental_id }
        opts_price = {}

        opts.each do |o|
            price = o.calculate(rental_days)
            opts_price[o.type.to_sym] = price.to_i
        end

        opts_price
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

    def self.options
        options = @data['options'].map do |o|
            Option.new(o)
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