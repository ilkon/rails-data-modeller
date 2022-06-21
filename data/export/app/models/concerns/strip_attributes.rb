# frozen_string_literal: true

module StripAttributes
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def strip_attributes(obj, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      attributes = [obj] + args

      AttributeStripper.validate(attributes, options)

      before_validation do |record|
        AttributeStripper.strip(record, attributes, options)
      end
    end
  end
end

module AttributeStripper
  VALID_OPTIONS = %i[allow_empty collapse_spaces replace_newlines regex].freeze

  # Unicode invisible and whitespace characters.  The POSIX character class
  # [:space:] corresponds to the Unicode class Z ("separator"). We also
  # include the following characters from Unicode class C ("control"), which
  # are spaces or invisible characters that make no sense at the start or end
  # of a string:
  #   U+180E MONGOLIAN VOWEL SEPARATOR
  #   U+200B ZERO WIDTH SPACE
  #   U+200C ZERO WIDTH NON-JOINER
  #   U+200D ZERO WIDTH JOINER
  #   U+2060 WORD JOINER
  #   U+FEFF ZERO WIDTH NO-BREAK SPACE
  MULTIBYTE_WHITE = "\u180E\u200B\u200C\u200D\u2060\uFEFF"
  MULTIBYTE_SPACE = /[[:space:]#{MULTIBYTE_WHITE}]/
  MULTIBYTE_BLANK = /[[:blank:]#{MULTIBYTE_WHITE}]/

  class << self
    def strip(record, attributes, options)
      attributes.each do |attr|
        original_value = record[attr]
        new_value = strip_string(original_value, options)
        record[attr] = new_value if original_value != new_value
      end

      record
    end

    def strip_string(value, options)
      if value.respond_to?(:strip)
        value = value.blank? && !options[:allow_empty] ? nil : value.strip
      end

      value.gsub!(options[:regex], '') if options[:regex] && value.respond_to?(:gsub!)

      if value.respond_to?(:gsub!) && Encoding.compatible?(value, MULTIBYTE_SPACE)
        value.gsub!(/\A#{MULTIBYTE_SPACE}+|#{MULTIBYTE_SPACE}+\z/, '')
      elsif value.respond_to?(:strip!)
        value.strip!
      end

      value.gsub!(/[\r\n]+/, ' ') if options[:replace_newlines] && value.respond_to?(:gsub!)

      if options[:collapse_spaces]
        if value.respond_to?(:gsub!) && Encoding.compatible?(value, MULTIBYTE_BLANK)
          value.gsub!(/#{MULTIBYTE_BLANK}+/, ' ')
        elsif value.respond_to?(:squeeze!)
          value.squeeze!(' ')
        end
      end

      value
    end

    def validate(attributes, options)
      attributes.each do |attr|
        raise ArgumentError, "Attribute is not a string or symbol (#{attr.inspect})" unless attr.is_a?(String) || attr.is_a?(Symbol)
      end
      raise ArgumentError, "Options does not specify #{VALID_OPTIONS} (#{options.keys.inspect})" unless (options.keys - VALID_OPTIONS).empty?
    end
  end
end
