require 'rubygems'
require 'zk'
require 'json'

# Considerations
#
# * Should we use HTTPS as a default? Should we have no protocol opinion and just use hostname and port?
#   Would some services need to provide more than that? Should it be a flexible JSON object, the meaning
#   of which must be known to clients?
# * Should location be data of the instance znode, or of a ./location znode?
# * Should we use one global ZK and make environment part of the service znode path?
#   One ZK per environment?
#
module ServiceDiscovery
  class ServiceRegistration
    attr_reader :service, :environment, :instance, :location

    def initialize(service: nil, environment: nil, instance: nil, location: nil)
      @service = service         or raise ArgumentError.new("service not specified")
      @environment = environment or raise ArgumentError.new("environment not specified")
      @instance = instance       or raise ArgumentError.new("instance not specified")
      @location = location       or raise ArgumentError.new("location not specified")
      @zk = nil
    end

    def register
      @zk = ZK.new(ENV["ZK_HOST"] || "localhost:2181")

      @zk.create("/service", :ignore => :node_exists)
      @zk.create("/service/#{@service}", :ignore => :node_exists)
      @zk.create("/service/#{@service}/#{@environment}", :ignore => :node_exists)
      @zk.create("/service/#{@service}/#{@environment}/instance", :ignore => :node_exists)

      @zk.create("/service/#{@service}/#{@environment}/instance/#{@instance}", {location: @location}.to_json, mode: :ephemeral)
      nil
    end

    def deregister
      raise "not registered" unless registered?
      @zk.delete("/service/#{@service}/#{@environment}/instance/#{@instance}")
      @zk = nil
    end

    def registered?
      @zk and !@zk.closed?
    end

  end
end
