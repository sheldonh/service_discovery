$:.unshift('./lib')
require 'service_discovery/service_context'
require 'service_discovery/provider/zoo_keeper_service_registry'
require 'service_discovery/service_registry'

ZK_HOST = if ENV['ZK_HOST']
            ENV['ZK_HOST']
          elsif ENV['DOCKER_HOST'] and ENV['DOCKER_HOST'] =~ /^tcp:\/\/([^:]+):*.*/
            "#{$1}:2181"
          else
            "localhost:2181"
          end

service_context = ServiceDiscovery::ServiceContext.new(domain_perspective: 'testing', service: 'irb', protocol: 'http')
provider = ServiceDiscovery::Provider::ZooKeeperServiceRegistry.new(hosts: ZK_HOST)
registry = ServiceDiscovery::ServiceRegistry.new(environment: 'test', provider: provider)
