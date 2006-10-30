require 'asym_crypt'

module ActiveRecord#:nodoc:
  # Asymetric encryption of ActiveRecord attributes.
  #
  # This extension allows asymetric encryption both for digital signing (encrypted with private key, and decrypted with public key),
  # and the more common case of encryption with a public key, only decryptable with a private key.
  #
  # Using this you can, for example, encrypt your customers credit card details with a public key stored on your webserver.  You can then
  # write a processing application on a different server, which has the private key and can read the data.  Another approach might be
  # to have the appropriate user paste the private key into a form, which is then kept for the session in the user's browser via a
  # cookie (*not* in the session, or server).
  # 
  # Both of these approaches keep the encryption and decryption methods separated and the keys are never in the same place (on the server)
  #
  # == Usage
  #
  # asym_encrypt <em>decrypted_attr</em>, :as => <em>crypt_col</em> [, options]
  #
  # Typically <em>crypt_col</em> will be a database column.  <em>decrypted_attr</em> becomes
  # an encryption wrapper for the database column.  The following accessor methods are created:
  #
  # * <tt>decrypted_attr=</tt> encrypts the argument with the encryption key (see below for how keys are found).  Raises EncryptionKeyRequired if none can be found.
  # * <tt>decrypted_attr</tt> decrypts (and caches) the argument with the decryption key.  Raises DecryptionKeyRequired if none can be found.
  # * <tt>decrypted_attr?</tt> returns true if there is a non false, nor nil, decrypted object, without raising any errors
  #
  # Unlike serialize, asym_crypt keeps the database column (in this case the cryptext) encoded in its original format.  This
  # allows the possibility of copying a record without knowing how to decrypt all of its attributes.
  #
  # === Options
  # * <tt>:encryption_key</tt>: use specified key (an AysmCrypt::Key) to encrypt this attribute
  # * <tt>:decryption_key</tt>: use specified key (an AsymCrypt::Key) to decrypt this attribute
  # * <tt>:class</tt>: make sure the decrypted object is of the specifed class, raising SerializationTypeMismatch if not
  # 
  # The encryption and decryption keys can be specified on the class, and these will be used for all (en/de)cryption if the
  # keys are not specified on the attribute.  They can also be specified on a per-object basis (both encryption_key and attr_encryption_key)
  # which allows for one-time usage of certain keys (probably private ones) without worrying about them beiing kept in the class variables.
  #
  # If you want to set key(s) for your whole application, then do this:
  #
  #   ActiveRecord::AsymCrypt.encryption_key = (your key)
  #   ActiveRecord::AsymCrypt.decryption_key = (your key)
  #
  # Keys will be searched first for attribute specific keys (on object instance, then class), then for a class specific key
  # (on object instance, then class), and finally on ActiveRecord::AsymCrypt
  #
  # See AsymCrypt for details on creating and reading keys.
  #
  # === Example
  #   class Secret < ActiveRecord::Base
  #     asym_encrypt :secret, :as => :secret_crypt
  #   end
  #
  #   @secret = Secret.new
  #   @secret.asym_encrypted_attributes       # => {:secret => {:as => :secret_crypt, :class => Object}}
  # 
  #   @secret.secret = 'I am green'           
  #   @secret.secret_crypt                    # => raises EncryptionKeyRequired
  #   @secret.save                            # => raises EncryptionKeyRequired
  #
  #   Secret.encryption_key = AsymCrypt.key_from_file('my/key/location.pub')
  #                                           # set public key for encryption on class
  #
  #   @secret.secret_encryption_key           # => the AsymCrypt::PublicKey above
  #   @secret.secret_decryption_key           # => nil
  #   
  #   @secret.secret?                         # => true
  #   @secret.secret_crypt                    # => (the cryptext)
  #   @secret.secret                          # => 'I am green'
  #
  #   @secret.reload
  #
  #   @secret.secret                          # raies DecryptionKeyRequired
  #   @secret.secret_decryption_key =  AsymCrypt.key_from_file('my/key/location')
  #                                           # set decryption key for secret attribute
  #                                           # this will go away when object does
  #
  #   @secret.secret                          # => 'I am green'
  #  
  module AsymCrypt
    
    class EncryptionKeyRequired < ::RuntimeError; end
    
    class DecryptionKeyRequired < ::RuntimeError; end
    
    mattr_accessor :encryption_key, :decryption_key
    
    def asym_encrypt(attr_name, options = {})
      append_features_to_active_record unless self.included_modules.include? ActiveRecord::AsymCrypt::InstanceMethods
      raise ArgumentError, 'asym_encrypt requires :as => crypt_col option' unless options[:as]
      define_asym_crypt_methods(attr_name, options)
      asym_encrypted_attributes[attr_name] = {:as => options[:as], :class => options[:class] || Object}
      send("#{attr_name}_encryption_key=", options[:encryption_key])
      send("#{attr_name}_decryption_key=", options[:decryption_key])
    end
  
  protected
    def append_features_to_active_record
      self.class_eval do
        extend ClassMethods
        include InstanceMethods        
        class_inheritable_accessor :encryption_key, :decryption_key 
        attr_accessor :encryption_key, :decryption_key
        before_save :encrypt_attributes
      end
    end
    
    def define_asym_crypt_methods(attr_name, config)
      crypt_col = config[:as].to_s
      
      class_eval do
        # key accessors at class and object level
        class_inheritable_accessor "#{attr_name}_encryption_key", "#{attr_name}_decryption_key"
        attr_accessor "#{attr_name}_encryption_key", "#{attr_name}_decryption_key"
        
        # accessors for encryption wrapper attribute
        attr_writer attr_name
        
        define_method "#{attr_name}?" do
          !!(send(attr_name) rescue nil)
        end
        
        # returns current plain attr, or attempt to decrypt
        define_method attr_name do
          instance_variable_get("@#{attr_name}") or instance_variable_set("@#{attr_name}", decrypt_attribute(attr_name, read_attribute(crypt_col)))
        end
        
        # writer for encrypted attribute, which clears the cached plain attribute
        define_method "#{crypt_col}=" do |cryptext|
          instance_variable_set("@#{attr_name}", nil)
          write_attribute(crypt_col, cryptext)
        end
        
        # we encrypt every time this is accessed in case the content of the plain attr has changed (i.e. is not value object)
        define_method crypt_col do
          if instance_variable_get("@#{attr_name}")
            write_attribute(crypt_col, encrypt_attribute(attr_name, instance_variable_get("@#{attr_name}")))
          else
            read_attribute(crypt_col)
          end
        end
      end
    end
        
    module InstanceMethods
      def self.included(base)
        base.class_eval do
          alias_method_chain :reload, :asym_crypt
        end
      end
      
      def reload_with_asym_crypt
        encrypted_attributes.keys.each {|attr_name| instance_variable_set("@#{attr_name}", nil)}
        reload_without_asym_crypt
      end
      
      def encrypted_attributes
        self.class.asym_encrypted_attributes
      end
    
    protected
      def encrypt_attributes
        encrypted_attributes.each {|_, config| send(config[:as]) }
      end

      # returns the first key found in the following order
      #   1. object instance variable for attribute-specific key
      #   2. class variable for attribute-specific key
      #   3. object instance variable for class-specific key
      #   4. class variable for class-specific key
      #   5. ActiveRecord::AsymCrypt default key
      #   6. nil
      #
      # The point of storing keys on the ActiveRecord object is so that a key can be
      # assigned for a tenproary operation, and it goes away when the object goes away.
      # 
      # For a public/private scenario described in the module comment,
      # you would set the encryption keys once, at the class level, and set the
      # private keys on particular objects that need to decrypt info, when they need it
      #
      
    protected
      def get_key(type, attr_name = nil)
        (attr_name and send "#{attr_name}_#{type}_key") or
        (attr_name and self.class.send "#{attr_name}_#{type}_key") or
        send "#{type}_key" or
        self.class.send "#{type}_key" or
        ::ActiveRecord::AsymCrypt.send "#{type}_key" 
      end

      def encrypt_attribute(attr_name, plain)  
        key = get_key(:encryption, attr_name)
        raise EncryptionKeyRequired unless key.is_a?(::AsymCrypt::Key)
        raise ::ActiveRecord::SerializationTypeMismatch unless plain.is_a?(encrypted_attributes[attr_name][:class])
        key.encrypt(plain)
      end
      
      def decrypt_attribute(attr_name, cryptext)
        return nil if cryptext.nil?
        raise DecryptionKeyRequired unless (key = get_key(:decryption, attr_name)).is_a?(::AsymCrypt::Key)
        plain = key.decrypt(cryptext)
        raise ::ActiveRecord::SerializationTypeMismatch unless plain.is_a?(encrypted_attributes[attr_name][:class])
        plain
      end
    end
    
    module ClassMethods
      def asym_encrypted_attributes
        read_inheritable_attribute("attr_asym_encrypted") or write_inheritable_attribute("attr_asym_encrypted", {})
      end
    end
  end
end