# frozen_string_literal: true

module Attributor
  class << self
    WRITER_METHODS = %i[
      password_length
      phone_length
    ].freeze
    attr_writer(*WRITER_METHODS)

    def configure
      yield self if block_given?
    end

    def password_regexp
      %r{
        \A
        (?=.*\d)                                      # Must contain a digit
        (?=.*[a-z])                                   # Must contain a lowercase character
        (?=.*[A-Z])                                   # Must contain an uppercase character
        (?=.*[!"#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~])  # Must contain a special character
      }x
    end

    def password_length
      @password_length || (8..64)
    end

    def email_regexp
      /\A[^@\s]+@([^@\s]+\.)+[^@\W]+\z/
    end

    def phone_regexp
      /[\d\s+\-#*@&.,()]+/
    end

    def phone_length
      @phone_length || (3..40)
    end

    def money_regexp
      /[+\-]?[\d.,]+/
    end

    def url_regexp
      %r{
        \A
        (?:(?:https?|ftp)://)                                         # scheme
        (?:\S+(?::\S*)?@)?                                            # user:pass authentication
        (?:
          (?!10(?:\.\d{1,3}){3})                                      # IP address exclusion
          (?!127(?:\.\d{1,3}){3})                                     # private & local networks
          (?!169\.254(?:\.\d{1,3}){2})
          (?!192\.168(?:\.\d{1,3}){2})
          (?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})
          (?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])                          # IP address dotted notation octets
          (?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}                     # excludes loopback network 0.0.0.0, reserved space >= 224.0.0.0, network & broacast addresses
          (?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))                   # (first & last IP address of each class)
        |
          (?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)     # host name
          (?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*  # domain name
          (?:\.(?:[a-z\u00a1-\uffff]{2,}))                            # TLD identifier
        )
        (?::\d{2,5})?                                                 # port number
        (?:/\S*)?                                                     # resource path
        \z
      }xi
    end
  end
end
