require 'nexpose-runner/constants'
require 'nexpose'

module NexposeRunner
  module Scan
    def Scan.start(connection_url, username, password, port, site_name, ip_address, scan_template)

      raise StandardError, CONSTANTS::REQUIRED_CONNECTION_URL_MESSAGE if connection_url.nil? || connection_url.empty?
      raise StandardError, CONSTANTS::REQUIRED_USERNAME_MESSAGE if username.nil? || username.empty?
      raise StandardError, CONSTANTS::REQUIRED_PASSWORD_MESSAGE if password.nil? || password.empty?
      raise StandardError, CONSTANTS::REQUIRED_SITE_NAME_MESSAGE if site_name.nil? || site_name.empty?
      raise StandardError, CONSTANTS::REQUIRED_IP_ADDRESS_MESSAGE if ip_address.nil? || ip_address.empty?
      raise StandardError, CONSTANTS::REQUIRED_SCAN_TEMPLATE_MESSAGE if scan_template.nil? || scan_template.empty?

      port = CONSTANTS::DEFAULT_PORT if port.nil? || port.empty?

      nsc = Nexpose::Connection.new connection_url, username, password, port
      nsc.login
      site = Nexpose::Site.new site_name, scan_template
      site.add_ip ip_address
      site.save nsc
    end
  end
end