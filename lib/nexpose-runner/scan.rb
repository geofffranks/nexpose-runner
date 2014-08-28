require 'nexpose'
require 'csv'
require 'nexpose-runner/constants'
require 'nexpose-runner/scan_run_description'


module NexposeRunner
  module Scan
    def Scan.start(connection_url, username, password, port, site_name, ip_address, scan_template)

      run_details = ScanRunDescription.new connection_url, username, password, port, site_name, ip_address, scan_template
      run_details.verify

      nsc = get_new_nexpose_connection(run_details)

      site = create_site(run_details, nsc)

      start_scan(nsc, site, run_details)

      reports = generate_reports(nsc, site, run_details)

      verify_run(reports[0])
    end

    def self.generate_reports(nsc, site, run_details)
      puts "Scan complete for #{run_details.site_name}, Generating Vulnerability Report"
      vulnerbilities = generate_report(CONSTANTS::VULNERABILITY_REPORT_QUERY, site.id, nsc)
      generate_csv(vulnerbilities, CONSTANTS::VULNERABILITY_REPORT_NAME)

      puts "Scan complete for #{run_details.site_name}, Generating Software Report"
      software = generate_report(CONSTANTS::SOFTWARE_REPORT_QUERY, site.id, nsc)
      generate_csv(software, CONSTANTS::SOFTWARE_REPORT_NAME)

      puts "Scan complete for #{run_details.site_name}, Generating Policy Report"
      policies = generate_report(CONSTANTS::POLICY_REPORT_QUERY, site.id, nsc)
      generate_csv(policies, CONSTANTS::POLICY_REPORT_NAME)

      [vulnerbilities, software, policies]
    end

    def self.verify_run(vulnerabilities)
      raise StandardError, CONSTANTS::VULNERABILITY_FOUND_MESSAGE if vulnerabilities.count > 0
    end

    def self.start_scan(nsc, site, run_details)

      puts "Starting scan for #{run_details.site_name} using the #{run_details.scan_template} scan template"
      scan = site.scan nsc

      begin
        sleep(3)
        status = nsc.scan_status(scan.id)
        puts "Current #{run_details.site_name} scan status: #{status.to_s}"
      end while status == Nexpose::Scan::Status::RUNNING
    end

    def self.create_site(run_details, nsc)
      puts "Creating a nexpose site named #{run_details.site_name}"
      site = Nexpose::Site.new run_details.site_name, run_details.scan_template
      site.add_ip run_details.ip_address
      site.save nsc
      puts "Created site #{run_details.site_name} successfully with the following host #{run_details.ip_address}"
      site
    end

    def self.get_new_nexpose_connection(run_details)
      nsc = Nexpose::Connection.new run_details.connection_url, run_details.username, run_details.password, run_details.port
      nsc.login
      puts 'Successfully logged into the Nexpose Server'
      nsc
    end

    def self.generate_report(sql, site, nsc)
      report = Nexpose::AdhocReportConfig.new(nil, 'sql')
      report.add_filter('version', '1.3.0')
      report.add_filter('query', sql)
      report.add_filter('site', site)
      report_output = report.generate(nsc)
      CSV.parse(report_output.chomp, {:headers => :first_row})
    end

    def self.generate_csv(csv_output, name)
      CSV.open(name, 'w') do |csv_file|
        csv_file << csv_output.headers
        csv_output.each do |row|
          csv_file << row
        end
      end
    end
  end
end
