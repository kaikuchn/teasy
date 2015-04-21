# Teasy

Timezone handling made easy.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'teasy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install teasy

## Usage

### TimeWithZone
#### Create a TimeWithZone object
```ruby
# Simply call the constructor
Teasy::TimeWithZone.new(2042, 4, 2, 0, 30, 45, 1.112, 'Europe/Berlin') # -> 2042-04-02 00:30:45 +0200

# leaving out the time zone will result in the default time zone being used, which by default is UTC
Teasy::TimeWithZone.new(2042, 4, 2, 0, 30, 45, 1.112) # -> 2042-04-02 00:30:45 UTC

# that default time zone can be set though
Teasy.default_zone = 'America/New_York' # -> "America/New_York"
Teasy::TimeWithZone.new(2042, 4, 2, 0, 30, 45, 1.112) # -> 2042-04-02 00:30:45 -0400

# you can also use the block syntax to temporarily change the default time zone
Teasy.with_zone('Europe/Berlin') do
  Teasy::TimeWithZone.new(2042, 4, 2, 0, 30, 45, 1.112) # -> 2042-04-02 00:30:45 +0200
end

# You can also initialize a Teasy::TimeWithZone object from time objects
Teasy::TimeWithZone.from_time(Time.utc(2042), 'Europe/Berlin') # -> 2042-01-01 00:00:00 +0100
Teasy::TimeWithZone.from_time(Time.utc(2042), 'America/New_York') # -> 2042-01-01 00:00:00 -0500

# this method interpretes the time object to be in the time zone specified, 
# if you want it to convert to another time zone use #from_utc instead
# where it is assumed that the time object is in UTC time.
Teasy::TimeWithZone.from_utc(Time.utc(2042), 'Europe/Berlin') # -> 2042-01-01 01:00:00 +0100
Teasy::TimeWithZone.from_utc(Time.utc(2042), 'America/New_York') # -> 2041-12-31 19:00:00 -0500
```

#### Convert between time zones
```ruby
# convert a Teasy::TimeWithZone object in place to another time zone by calling #in_time_zone!
time_with_zone # -> 2042-01-01 01:00:00 +0100
time_with_zone.in_time_zone!('America/New_York') # -> 2041-12-31 19:00:00 -0500
time_with_zone # -> 2041-12-31 19:00:00 -0500

# convert it without changing the original object by calling #in_time_zone
time_with_zone # -> 2042-01-01 01:00:00 +0100
time_with_zone.in_time_zone('Asia/Calcutta') # -> 2042-01-01 05:30:00 +0530
time_with_zone # -> 2042-01-01 01:00:00 +0100
```

#### Comparisons
As long as a `TimeWithZone` converts to the same utc time it is `==` and `eql?` to another `TimeWithZone`.
If the other is not a `TimeWithZone`, then only `==` will return true (since it performs a conversion), given that other responds to `to_time`. `eql?` will not perform a conversion - similiar to how `Numeric` works in Ruby.

Examples:
```ruby
calcutta_time = Teasy::TimeWithZone.from_utc(Time.utc(2042), 'Asia/Calcutta') # -> 2042-01-01 05:30:00 +0530
ny_time = Teasy::TimeWithZone.from_utc(Time.utc(2042), 'America/New_York') # -> 2041-12-31 19:00:00 -0500

ny_time == calcutta_time # -> true
ny_time.eql? calcutta_time # -> true

calcutta_time == Time.utc(2042) # -> true
calcutta_time.eql? Time.utc(2042) # -> false
```

### FloatingTime
#### Create a FloatingTime object
```ruby
# Simply call the constructor
Teasy::FloatingTime.new(2042, 4, 2, 0, 30, 45, 1.112) # -> 2042-04-02 00:30:45

# or create one from a time object
Teasy::FloatingTime.from_time(Time.utc(2042)) # -> 2042-01-01 00:00:00

# the zone doesn't matter
Teasy::FloatingTime.from_time(Time.local(2042)) # -> 2042-01-01 00:00:00

# also, it doesn't have to be a time object, as long as it responds to
# :year, :mon, :day, :hour, :min, :sec and :nsec
time_with_zone = Teasy::TimeWithZone.from_time(Time.utc(2042), 'Asia/Calcutta') # -> 2042-01-01 00:00:00 +0530
Teasy::FloatingTime.from_time(time_with_zone) # -> 2042-01-01 00:00:00
```

#### Comparisons
When the year, month, day, hour, minute, second and nano-second of two `FloatingTime` objects are the same then `eql?` and `==` return true. When the other object is not a FloatingTime but responds to `to_time` and `utc_offset` then `==` will return true if the aforementioned list of attributes are equal. However, `eql?` again does not perform any conversion and thus will return false for any object that is not a `FloatingTime`.

Examples:
```ruby
floating_time = Teasy::FloatingTime.from_time(Time.utc(2042)) # -> 2042-01-01 00:00:00
other_floating_time = Teasy::FloatingTime.from_time(Time.utc(2042, 1, 1, 1)) # -> 2042-01-01 01:00:00
ny_time = Teasy::TimeWithZone.from_time(Time.utc(2042), 'America/New_York') # -> 2042-01-01 00:00:00 -0500
other_ny_time = Teasy::TimeWithZone.from_utc(Time.utc(2042), 'America/New_York') # -> 2041-12-31 19:00:00 -0500

floating_time == other_floating_time # -> false
floating_time.eql? other_floating_time # -> false

floating_time == floating_time.dup # -> true
floating_time.eql? floating_time.dup # -> true

floating_time == Time.utc(2042) # -> true
floating_time == ny_time # -> true
floating_time == other_ny_time # -> false
[Time.utc(2042), ny_time, other_ny_time].any? { |time| floating_time.eql? time } # -> false
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/teasy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
