module TimeSplitter
  module Accessors
    def split_accessor(*attrs)
      options = attrs.extract_options!

      attrs.each do |attr|
        # Maps the setter for #{attr}_time to accept multipart-parameters for Time
        composed_of "#{attr}_time".to_sym, class_name: 'DateTime' if self.respond_to?(:composed_of)

        # Default instance of the attribute, used if setting an element of the
        # time attribute before the attribute was sent. Allows us to retrieve a
        # default value for +#{attr}+ to modify without explicitely overriding
        # the attr_reader. Defaults to a Time object with all fields set to 0.
        define_method("#{attr}_or_new") do
          self.send(attr) || options.fetch(:default, ->{ Time.new(0, 1, 1, 0, 0, 0, "+00:00") }).call
        end

        # Writers

        define_method("#{attr}_year=") do |year|
          return unless year.present?
          self.send("#{attr}=", self.send("#{attr}_or_new").change(year: year))
        end

        define_method("#{attr}_month=") do |month|
          return unless month.present?
          self.send("#{attr}=", self.send("#{attr}_or_new").change(month: month))
        end

        define_method("#{attr}_day=") do |day|
          return unless day.present?
          self.send("#{attr}=", self.send("#{attr}_or_new").change(day: day))
        end

        define_method("#{attr}_date=") do |date|
          return unless date.present?
          unless date.is_a?(Date) || date.is_a?(Time)
            if options[:date_format]
              date = Date.strptime(date.to_s, options[:date_format])
            else
              date = Date.parse(date.to_s)
            end
          end
          self.send("#{attr}=", self.send("#{attr}_or_new").change(year: date.year, month: date.month, day: date.day))
        end

        define_method("#{attr}_hour=") do |hour_string|
          return unless hour_string.present?

          if hour_string.is_a?(Time)
            hour_time = hour_string
          else
            hour_time = Time.strptime(hour_string.to_s, "%H")
          end

          hour_time = self.send("#{attr}_correct_for_offset", hour_time, "%H")
          self.send("#{attr}=", self.send("#{attr}_or_new")
              .change(hour: hour_time.hour, min: self.send("#{attr}_or_new").min))
        end

        define_method("#{attr}_min=") do |min|
          return unless min.present?
          self.send("#{attr}=", self.send("#{attr}_or_new").change(min: min))
        end

        define_method("#{attr}_time=") do |time|
          return unless time.present?
          return if time.is_a?(Date)

          unless time.is_a?(Time)
            if options[:time_format]
              time = Time.strptime(time, options[:time_format])
            else
              time = Time.parse(time)
            end
          end

          time = self.send("#{attr}_correct_for_offset", time, options[:time_format] || "%H:%M")

          self.send("#{attr}=", self.send("#{attr}_or_new").change(hour: time.hour, min: time.min))
        end

        # Readers
        define_method("#{attr}_year") do
          self.send(attr).try :month
        end

        define_method("#{attr}_month") do
          self.send(attr).try :month
        end

        define_method("#{attr}_day") do
          self.send(attr).try :day
        end

        define_method("#{attr}_date") do
          date = self.send(attr).try :to_date
          date && options[:date_format] ? date.strftime(options[:date_format]) : date
        end

        define_method("#{attr}_hour") do
          self.send(attr).try :hour
        end

        define_method("#{attr}_min") do
          self.send(attr).try :min
        end

        define_method("#{attr}_time") do
          time = self.send(attr)
          time && options[:time_format] ? time.strftime(options[:time_format]) : time
        end

        # If input time has a zone with an offset from UTC, this method creates a time object
        # with the correct offset. Then converts that time to UTC.
        define_method("#{attr}_correct_for_offset") do |time, format|
          return time unless options[:input_time_utc_offset]
          time = Time.strptime(time.strftime("#{format} #{options[:input_time_utc_offset]}"), "#{format} %z")
            .in_time_zone("UTC")
        end
      end
    end
  end
end
