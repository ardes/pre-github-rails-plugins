require 'openssl'
require 'yaml'
require 'base64'

module AsymCrypt
  
  class BadKey < RuntimeError; end
  
  # returns an rsa key pair of the required strength (in bits) object
  def self.create_keys(strength = 1024)
    private_key = OpenSSL::PKey::RSA.new(strength)
    [PrivateKey.new(private_key.to_s), PublicKey.new(private_key.public_key.to_s)]
  end
  
  # create key files, return the keys
  def self.create_key_files(priv_file = "key", pub_file = "#{priv_file}.pub", strength = 1024)
    (private_key, public_key) = create_keys(strength)
    private_key.to_file(priv_file)
    public_key.to_file(pub_file)
    [private_key, public_key]
  end
  
  def self.key(data)
    data =~ /BEGIN (.*)PRIVATE KEY/ ? PrivateKey.new(data) : PublicKey.new(data)
  end

  def self.key_from_file(filename)
    key(File.read(filename))
  end
  
  def self.keys_from_file(priv_file, pub_file = "#{priv_file}.pub")
    [key_from_file(priv_file), key_from_file(pub_file)]
  end
  
  class Key
    attr_reader :type
    
    def to_s
      @key.to_s
    end
    
    def to_file(filename)
      File.open(filename, "w+") { |fp| fp << self.to_s }
    end
    
    def decrypt(cryptext)
      YAML::load(@key.send("#{type}_decrypt", Base64.decode64(cryptext)))
    end

    def encrypt(object)
      Base64.encode64(@key.send("#{type}_encrypt", object.to_yaml))
    end
  end
  
  class PublicKey < Key
    def initialize(data)
      raise(ArgumentError, "data is not public key data") unless data =~ /BEGIN (.*)PUBLIC KEY/
      @key = OpenSSL::PKey::RSA.new(data)
      @type = :public
    end
    
  end
   
  class PrivateKey < Key
    def initialize(data)
      raise(ArgumentError, "data is not private key data") unless data =~ /BEGIN (.*)PRIVATE KEY/
      @key = OpenSSL::PKey::RSA.new(data)
      @type = :private
    end
  end
end