require 'fluent/plugin/filter'
require 'murmurhash3'

module Fluent::Plugin
  class GenHashValueFilter < Filter
    Fluent::Plugin.register_filter('genhashvalue', self)

    include MurmurHash3::V128

    config_param :keys, :array
    config_param :set_key, :string, :default => '_hash'
    config_param :inc_time_as_key, :bool, :default => true
    config_param :inc_tag_as_key, :bool, :default => true
    config_param :crop_string, :integer, :default => 20
    config_param :separator, :string, :default => '_'
    config_param :hash_type, :string, :default => 'sha256'
    config_param :remove_digit, :bool, :default => false
    config_param :base64_enc, :bool, :default => false
    config_param :base91_enc, :bool, :default => false

    def initialize
      super
      require 'base64'
      require 'base91'
    end

    def configure(conf)
      #$log.trace "configure #{conf}"
      super
    end

    def start
      super
      # init
    end

    def shutdown
      super
      # destroy
    end

    def filter(tag, time, record)
      s = ""
      s += tag + separator if inc_tag_as_key
      s += time.to_s + separator if inc_time_as_key

      s += keys.map {|k| record[k]}.join(separator)
      if remove_digit
      s.gsub!(/\d+/,"")
      end
      if base64_enc || base91_enc then
        record[set_key] = hash_enc(hash_type, s[0, $crop_string])
      else
        record[set_key] = hash_hex(hash_type, s[0, $crop_string])
      end
      record
    end

    def hash_hex(type, str)
      case type
      when 'md5'
        h = Digest::MD5.hexdigest(str)
      when 'sha1'
        h = Digest::SHA1.hexdigest(str)
      when 'sha256'
        h = Digest::SHA256.hexdigest(str)
      when 'sha512'
        h = Digest::SHA512.hexdigest(str)
      when 'mur128'
        h = MurmurHash3::V128.str_hexdigest(str)
      end
    end

    def hash_enc(type, str)
      case type
      when 'md5'
        h = Digest::MD5.digest(str)
      when 'sha1'
        h = Digest::SHA1.digest(str)
      when 'sha256'
        h = Digest::SHA256.digest(str)
      when 'sha512'
        h = Digest::SHA512.digest(str)
      when 'mur128'
        h = MurmurHash3::V128.str_digest(str)
      end
      if base64_enc then
        h = Base64::strict_encode64(h)
      elsif base91_enc then
        h = Base91::encode(h)
      end
    end
  end
end
