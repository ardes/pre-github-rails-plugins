require 'openssl'
require 'base64'

# Wrapper for OpenSSL to asymetrically (en/de)crypt arbitrarily large objects
#
# Also see ActiveRecord::AsymCrypt for easy encryption of active record fields.
#
# Use AsymCrypt.create_keys, or AsymCrypt.create_key_files to create a public/private key
# pair.
#
# Keys are of type AsymCrypt::Key, and can be either public or private.  You can encrypt or
# decrypt with either type of key (use the other type to decrypt or encyrpt the data).
#
# The encryption algorithm is to randomly generate an AES-256-CBC (strong symmetric encryption)
# iv and key, encyrpt the data with that, and then encrypt the key,iv pair with the 
# RSA key.
#
# Example:
#   
#   (private, public) = AsymCrypt.create_keys
#
#   cryptext = public.encrypt('Secret')
#   private.decrypt(cryptext) # => 'Secret'
#
#   # encrypting a large data structure
#   cryptext = public.encrypt((1..20000).to_a)
#   private.decrypt(cryptext).size # => 20000
#
#   # save the keys for later use
#   public.to_file('key.pub')
#   private.to_file('key.priv')
#
module AsymCrypt
  
  # returns an rsa key pair of the required strength (in bits) object
  def self.create_keys(bits = 2048)
    private_key = OpenSSL::PKey::RSA.new(bits)
    [Key.new(private_key.to_s), Key.new(private_key.public_key.to_s)]
  end

  # creates key files, returns the keys
  def self.create_key_files(priv_file = "key", pub_file = "#{priv_file}.pub", bits = 2048)
    (private_key, public_key) = create_keys(bits)
    private_key.to_file(priv_file)
    public_key.to_file(pub_file)
    [private_key, public_key]
  end
  
  def self.keys_from_file(priv_file, pub_file = "#{priv_file}.pub")
    [Key.from_file(priv_file), Key.from_file(pub_file)]
  end

  # encapsulates the required functionality of OpenSSL.  A key can be used to
  # encrypt an object, and decrypt a cryptext.
  class Key
    attr_reader :type

    def self.from_file(filename)
      new(File.read(filename))
    end
  
    def initialize(data)
      raise(ArgumentError, "data is not public or private key data") unless data =~ /BEGIN (.*)(PUBLIC|PRIVATE) KEY/
      @key = OpenSSL::PKey::RSA.new(data)
      @type = (data =~ /BEGIN (.*)PUBLIC KEY/) ? :public : :private
    end
  
    def to_s
      @key.to_s
    end
  
    def to_file(filename)
      File.open(filename, "w+") { |fp| fp << self.to_s }
    end
  
    # generate an AES-256-CBC key and iv, encrypt the data with that, and then RSA encrypt the key/iv
    # Assumption: the size of the RSA key, in bytes, is no greater than 65535 as the first two
    # bytes of the cryptext are used to store the rsa key size.
    # this poses no security risk if using decent sized keys - like: 2048 bits, the default.
    def encrypt(object)
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.encrypt
      key = cipher.random_key
      iv = cipher.random_iv
    
      ciphertext = cipher.update(Marshal.dump(object))
      ciphertext << cipher.final
    
      cipherkey = @key.send("#{type}_encrypt", key.size.chr + key + iv)
      cipherkeysize = (cipherkey.size/256).chr + (cipherkey.size%256).chr
      Base64.encode64(cipherkeysize + cipherkey + ciphertext)
    end

    # extract size of RSA key from first two bytes of cryptext, then the cipherkey,
    # then the ciphertext
    # the cipherkey contains the size of the aes key (in one byte), followed by the key and iv
    def decrypt(cryptext)
      cryptext = Base64.decode64(cryptext)
      cipherkeysize = cryptext[0]*256 + cryptext[1]
    
      cipherkey = @key.send("#{type}_decrypt", cryptext[2..cipherkeysize+1])
      ciphertext = cryptext[cipherkeysize+2..-1]
    
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.decrypt
      cipher.key = cipherkey[1..cipherkey[0]]
      cipher.iv = cipherkey[cipherkey[0]+1..-1]
    
      plain = cipher.update(ciphertext)
      plain << cipher.final
    
      Marshal::load(plain)
    end
  end
end