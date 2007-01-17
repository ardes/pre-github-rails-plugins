require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'

# Set of convenience methods for computing salted hash passwords.
#
# The return values for the hash, and salt are 8-bit binary strings.
# If you wish, you can convert these to hexadecimal strings using binary_to_hex
module SaltedHash
  SALT_LENGTH = 20
  
  # return array of the supported algorithms
  def self.algorithms
    ['md5', 'sha1', 'sha256', 'sha384', 'sha512']
  end
  
  # raise an error if the argument is not a supported algorithm
  def self.assert_supported_algorithm(algorithm)
    raise ArgumentError, "Unsupported algorithm '#{algorithm}'" unless algorithms.include?(algorithm.to_s.downcase)
  end
  
  # computes a hash given a digest algorithm name (see algorithms), salt string and password string
  def self.compute(algorithm, salt, password)
    assert_supported_algorithm(algorithm)
    digest = "Digest::#{algorithm.upcase}".constantize
    hex_to_binary(digest.hexdigest("#{salt}#{password}"))
  end
  
  # creates a random 8-bit binary string of SALT_LENGTH
  def self.salt
    (1..SALT_LENGTH).inject('') {|s,_| s << rand(256)}
  end
  
  # takes a string of hexadecimal pairs and converts it to a string of 8-bit bytes
  def self.hex_to_binary(hex)
    hex.unpack('a2' * (hex.length/2)).inject(''){|s,c| s << c.hex}
  end
  
  # takes an 8-bit binary string and converts it to a string of hexadecimal pairs
  def self.binary_to_hex(binary)
    binary.unpack('C' * binary.length).inject(''){|s,c| s << '%02x' % c}
  end
end