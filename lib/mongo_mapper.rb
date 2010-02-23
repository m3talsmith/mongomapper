require 'set'

begin
  # Require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require "active_model"
require "active_model/callbacks"
require "active_model/conversion"
require "active_model/deprecated_error_methods"
require "active_model/errors"
require "active_model/naming"
require "active_model/serialization"
require "active_model/translation"
require "active_model/validator"
require "active_model/validations"
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/module'

require 'mongo'

module MongoMapper
  # generic MM error
  class MongoMapperError < StandardError; end

  # raised when key expected to exist but not found
  class KeyNotFound < MongoMapperError; end

  # raised when document expected but not found
  class DocumentNotFound < MongoMapperError; end

  # raised when document not valid and using !
  class DocumentNotValid < MongoMapperError
    def initialize(document)
      super("Validation failed: #{document.errors.full_messages.join(", ")}")
    end
  end

  # @api public
  def self.connection
    @@connection ||= Mongo::Connection.new
  end

  # @api public
  def self.connection=(new_connection)
    @@connection = new_connection
  end

  # @api public
  def self.logger
    connection.logger
  end

  # @api public
  def self.database=(name)
    @@database = nil
    @@database_name = name
  end

  # @api public
  def self.database
    if @@database_name.blank?
      raise 'You forgot to set the default database name: MongoMapper.database = "foobar"'
    end

    @@database ||= MongoMapper.connection.db(@@database_name)
  end

  def self.config=(hash)
    @@config = hash
  end

  def self.config
    raise 'Set config before connecting. MongoMapper.config = {...}' unless defined?(@@config)
    @@config
  end

  def self.connect(environment, options={})
    raise 'Set config before connecting. MongoMapper.config = {...}' if config.blank?
    MongoMapper.connection = Mongo::Connection.new(config[environment]['host'], config[environment]['port'], options)
    MongoMapper.database = config[environment]['database']
    if config[environment]['username'].present? && config[environment]['password'].present?
      MongoMapper.database.authenticate(config[environment]['username'], config[environment]['password'])
    end
  end

  def self.setup(config, environment, options={})
    using_passenger = options.delete(:passenger)
    handle_passenger_forking if using_passenger
    self.config = config
    connect(environment, options)
  end

  def self.handle_passenger_forking
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        connection.connect_to_master if forked
      end
    end
  end

  # @api private
  def self.use_time_zone?
    Time.respond_to?(:zone) && Time.zone ? true : false
  end

  # @api private
  def self.time_class
    use_time_zone? ? Time.zone : Time
  end

  # @api private
  def self.normalize_object_id(value)
    value.is_a?(String) ? Mongo::ObjectID.from_string(value) : value
  end
  
  autoload :Query,            'mongo_mapper/query'
  autoload :Document,         'mongo_mapper/document'
  autoload :EmbeddedDocument, 'mongo_mapper/embedded_document'
end

require 'mongo_mapper/support'
require 'mongo_mapper/plugins'