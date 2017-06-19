# Teasy

Handling time zones in Ruby made easy.

## Why should anyone use this?

It is astonishingly [difficult to work with time zones in general](https://www.youtube.com/watch?v=-5wpm-gesOY) and with time zones in Ruby in particular. The only two time zones you can get from native Ruby are UTC and your local time zone. Apart from that you may set offsets, but that is not the same as setting a time zone.
This has prompted frameworks like Rails to develop classes like `ActiveSupport::TimeWithZone`. Since there is need for more than two time zones in web development.

When looking for ways to work with time zones in Ruby you will find that the general advice is either to just use ActiveSupport's TimeWithZone or to use the TZInfo gem. The former has two troubles, first you get more than you wanted. Even when you only require the minimal amount of ActiveSupport classes needed to get TimeWithZone running - which isn't a fun thing to figure out - you will also load monkey patches to core Ruby classes into your code. Second it has some serious quirks that can get you, like this goodie:
```ruby
t = DateTime.new(2014).in_time_zone('Europe/Berlin')
t.equal? t # -> true
t.eql? t # -> false ... WTF?
t == t # -> true
```
That was reported [here](https://github.com/rails/rails/issues/14178) a few years ago. Overall the interface of TimeWithZone is very nice though and this gem took strong inspiration from it. However I dislike monkey patching and decided not to include convenience methods like `in_time_zone` for `Time` objects.

[TZInfo](https://github.com/tzinfo/tzinfo) is a great gem that provides accurate time zone information and methods to determine the period for a point in time. However the interface it provides to convert time objects is minimal and rather difficult to use. Thus this gem uses TZInfo as a source for time zone information and tries to provide a nice interface for working with time with zones. (By the way, ActiveSupports' TimeWithZone is based on TZInfo too.)

This gem also comes with a FloatingTime class, which is time without a zone. I.e., 5 a.m. in New York is the same as 5 a.m. in Berlin with regards to floating time. This is useful for events that should occur at a certain time irrespective of time zone. E.g., your wake up call at 8 a.m. which you wouldn't want to ring at 2 in the morning just because you switched time zones.

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

#### Handling Period Not Found

Some periods do not exist. This is a problem you do not have to worry about as soon as you have successfully constructed a `Teasy::TimeWithZone` object, since all operations on existing `TimeWithZone` objects are safe in that way.
However, construction may fail when you choose invalid parameters. E.g., `Teasy::TimeWithZone.new(2014, 3, 30, 2, 30, 0, 0, 'Europe/Berlin')` does not exist since time advanced from 2 a.m. to 3 a.m. local time in the CET time zone on March the 30th, 2014 and thus no 2:30 a.m. exists.

By default we will raise a `TZInfo::PeriodNotFound` exception in this case. However, you may want to change this behaviour by defining a different period not found handler.

```ruby
# the default handler
Teasy.period_not_found_handler = :raise
Teasy::TimeWithZone.new(2014, 3, 30, 2, 30, 0, 0, 'Europe/Berlin')
# => TZInfo::PeriodNotFound: TZInfo::PeriodNotFound

# tell teasy to default to the previous period
Teasy.period_not_found_handler = :next_period
Teasy::TimeWithZone.new(2014, 3, 30, 2, 30, 0, 0, 'Europe/Berlin')
# => 2014-03-30 03:00:00 +0200

# tell teasy to default to the previous period
Teasy.period_not_found_handler = :previous_period
Teasy::TimeWithZone.new(2014, 3, 30, 2, 30, 0, 0, 'Europe/Berlin')
# => 2014-03-30 02:00:00 +0100

# or define a custom handler, it has to be callable and will receive a time object without
# zone information (it says UTC but it's not!) and the zone information object
Teasy.period_not_found_handler = lambda do |time, zone|
  warn "#{time} does not exist for #{zone}"
  Teasy::TimeWithZone.new(time.year)
end
```

If you want to change the behaviour for just one piece of code, the you can use the `Teasy::with_period_not_found_handler` method with a block.

#### Handling Ambiguous Time

Similarly to how some periods do not exist, sometimes time is ambiguous. Missing periods are the result from forward shifts in time, ambiguous time is due to backward shifts in time. E.g., `Teasy::TimeWithZone.new(2014, 10, 26, 2, 0, 0, 0, 'Europe/Berlin')` is ambiguous since the daylight savings time ended at 3 a.m. local time in central europe and the clocks were turned back to 2 a.m. Therefore it could be either CET (+1) or CEST (+2), you just cannot know.

By default we will raise a `TZInfo::AmbiguousTime` exception when this happens. However, you may, again, change the default behaviour in general or for a specific piece of code, like this:

```ruby
# the default handler
Teasy.ambiguous_time_handler = :raise
Teasy::TimeWithZone.new(2014, 10, 26, 2, 0, 0, 0, 'Europe/Berlin')
# => TZInfo::AmbiguousTime: 2014-10-26 02:00:00 UTC is an ambiguous local time

# tell teasy to default to the daylight savings time
Teasy.ambiguous_time_handler = :daylight_savings_time
Teasy::TimeWithZone.new(2014, 10, 26, 2, 0, 0, 0, 'Europe/Berlin')
# => 2014-10-26 02:00:00 +0200

# conversely tell teasy to default to the standard time
Teasy.ambiguous_time_handler = :standard_time
Teasy::TimeWithZone.new(2014, 10, 26, 2, 0, 0, 0, 'Europe/Berlin')
# => 2014-10-26 02:00:00 +0100

# or define a custom handler, it has to be callable and will receive a time object without
# zone information (it says UTC but it's not!) and the candidate periods. The periods are
# sorted by time and the block has to return a single period to resolve the ambiguity.
Teasy.ambiguous_time_handler = lambda do |time, periods|
  if time.minute < 30
    periods.first
  else
    periods.last
  end
end
```

Of course there's also a `Teasy::with_ambiguous_time_handler` methods that accepts a block and will reset the handler after the block.

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

#### Convert to a TimeWithZone

Simply call `in_time_zone` with a specific timezone to convert a floating time into a time with a zone, if the time exists in the given timezone, you shall get a `TimeWithZone` object.

## Contributing

1. Fork it ( https://github.com/kaikuchn/teasy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
