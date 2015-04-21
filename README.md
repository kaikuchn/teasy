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

# this method interpretes the time object to be in the time zone specified, if you want it to convert to another time zone use #from_utc instead where it is assumed that the time object is in UTC time.
Teasy::TimeWithZone.from_utc(Time.utc(2042), 'Europe/Berlin') # -> 2042-01-01 01:00:00 +0100
Teasy::TimeWithZone.from_utc(Time.utc(2042), 'America/New_York') # -> 2041-12-31 19:00:00 -0500

# Teasy::TimeWithZone object can be converted to other time zones by calling #in_time_zone or #in_time_zone! the latter converts the object itself the former creates a copy
time_with_zone = Teasy::TimeWithZone.from_utc(Time.utc(2042), 'Europe/Berlin') # -> 2042-01-01 01:00:00 +0100
time_with_zone.in_time_zone!('America/New_York') # -> 2041-12-31 19:00:00 -0500
time_with_zone.in_time_zone('Asia/Calcutta') # -> 2042-01-01 05:30:00 +0530
time_with_zone # -> 2041-12-31 19:00:00 -0500
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/teasy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
