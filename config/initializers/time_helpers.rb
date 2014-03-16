Time::DATE_FORMATS[:date] = lambda { |time| time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}, %Y") }
Time::DATE_FORMATS[:time_with_zone] = lambda { |time| time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}, %Y %I:%M %p (%Z)") }
