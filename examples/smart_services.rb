# Example of a service provider providing the service context to a service provider factory.
#
class ContactServiceRestProvider

  def self.service_context
    ServiceDiscovery::ServiceContext.new(domain_perspective: 'crm', service: 'contacts', protocol: 'http')
  end

  def initialize(service_registration: nil)
    KeywordSupport.import! binding
  end

  def get_contacts(client_number: nil)
    KeywordSupport.require! binding
    # rest = Rest.new(@service_location)
    # json = rest.get("/client/#{client_number}/contacts")
    # JSON.parse(json).each do { |properties| Contact.new(properties: properties) }

    [ Contact.new(properties: {email: 'sheldonh@starjuice.net', role: 'billing'}) ]
  end

  def service_uri
    @service_registration.uri
  end

end

class ContactService

  def initialize(provider: nil)
    KeywordSupport.import! binding
  end

  def get_invoice_recipients(client_number: nil)
    KeywordSupport.require! binding
    contacts = @provider.get_contacts(client_number: client_number)
    contacts.select { |c| c.role == 'billing' }
  end

end

class Contact

  attr_reader :email, :role

  def initialize(properties: nil)
    KeywordSupport.require! binding
    @email = properties[:email]
    @role = properties[:role]
  end

end

