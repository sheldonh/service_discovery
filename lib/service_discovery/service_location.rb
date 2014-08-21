require 'rubygems'
require 'zk'
require 'json'

module ServiceDiscovery
  class ServiceLocation
    attr_reader :service, :environment, :location

    def initialize(service: nil, environment: nil)
      @service = service         or raise ArgumentError.new("service not specified")
      @environment = environment or raise ArgumentError.new("environment not specified")
      @location = nil
    end

    def locate
      zk = ZK.new(ENV["ZK_HOST"] || "localhost:2181")
      instances = zk.children("/service/#{@service}/#{@environment}/instance")
      instance = instances.sample
      json = zk.get("/service/#{@service}/#{@environment}/instance/#{instance}")[0]
      data = JSON.parse(json, symbolize_names: true)
      @location = data[:location]
      nil
    end

  end
end
