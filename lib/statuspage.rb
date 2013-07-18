require 'rubygems'
require 'httparty'
require 'yaml'

class StatusPage
  COMPONENT_STATUSES = ["operational", "degraded performance", "partial outage", "major outage"]
  INCIDENT_STATUSES = ["investigating", "identified", "monitoring", "resolved"]

  def initialize(args=nil)
    @config = File.expand_path("~/statuspage.yml")
    @components = {}
    load_config
    load_components
    start(args) if args
  end
  
  def load_config
    config = YAML.load(File.open @config)
    @oauth = config['oauth']
    @base_url = config['base_url']
    @page = config['page']
  end

  def load_components
    httparty_send(:get, "#{@base_url}#{@page}/components.json").each {|c| @components[c['name'].downcase] = c['id'] }
  end

  def start(args=[])
    command = args.shift
    if self.respond_to? command
      send(command, *args)
    else
      puts "Command not recognized"
    end
  end

  # components - show status of all components
  # components <component_name> - show status of specific component
  # components <component_name> <status> - set the status for a component
  def components(*args)
    component_name_valid?(args[0]) unless args.empty?
    if args.empty?
      results = httparty_send :get, "#{@base_url}#{@page}/components.json"
      puts results
      results
    elsif args.size == 1
      component_name = @components.keys.grep(/#{args[0].downcase}/).first
      component_id = @components["#{component_name}"]

      results = httparty_send :get, "#{@base_url}#{@page}/components.json"
      component = results.select{|c| c['id'] == component_id}.first
      puts "Status of #{component['name']}: #{component['status'].gsub('_',' ')}"
    else 
      valid_component_status?(args[1])
      component_name = @components.keys.grep(/#{args[0].downcase}/).first
      component_id = @components["#{component_name}"]
      component_new_status = COMPONENT_STATUSES.grep(/#{args[1].downcase}/).first
      url = "#{@base_url}#{@page}/components/#{component_id}.json"

      results = httparty_send :patch, url, :body => {"component[status]" => component_new_status.gsub(' ', '_')}
      puts "Status for #{component_name} is now #{results['status'].gsub('_',' ')}"
    end
  end

  # incidents - show json of all incidents
  # incidents open <incident_name> <incident_status> <incident_message> - create new incident
  # incidents update <incident_status> <incident_message> - update last open incident with new status/message
  def incidents(*args)
    if args.empty?
      results = httparty_send :get, "#{@base_url}#{@page}/incidents.json"
      incidents = results.reject {|i| ['resolved', 'postmortem', 'completed'].include? i['status']}
      if incidents.empty?
        puts "All clear, no unresolved incidents!"
      else
        puts "Unresolved incidents:"
        incidents.each do |i|
          puts "#{i['name']} - status: #{i['status']}, created at #{i['created_at']}"
        end
      end
    elsif args[0] == 'open'
      valid_incident_status?(args[2])
      options = { :body => { "incident[name]" => args[1], "incident[status]" => args[2],  "incident[message]" => args[3] } }
      results = httparty_send :post, "#{@base_url}#{@page}/incidents.json", options
      puts results
    elsif args[0] == 'update'
      latest_incident = incidents.reject {|i| ['resolved', 'postmortem', 'completed'].include? i['status']}.first
      if latest_incident.nil?
        puts "No open incidents"
      else
        valid_incident_status?(args[1])
        options = { :body => { "incident[status]" => args[1],  "incident[message]" => args[2] } }
        results = httparty_send :patch, "#{@base_url}#{@page}/incidents/#{latest_incident['id']}.json", options
        puts results
      end
    else
      puts "Invalid command"
    end
  end

  private

  def component_name_valid?(name)
    unless @components.keys.detect {|n| n =~ /#{name}/}
      puts "Invalid component name"
      exit
    end
    true
  end

  def valid_component_status?(status)
    unless COMPONENT_STATUSES.grep(/#{status}/)
      raise "#{status} is not a valid component status. Please pick one of the following: #{COMPONENT_STATUSES.to_s}"
    end
    true
  end

  def valid_incident_status?(status)
    unless INCIDENT_STATUSES.include? status
      raise "#{status} is not a valid incident status. Please pick one of the following: #{INCIDENT_STATUSES.to_s}"
    end
    true
  end

  def httparty_send(action, url, options={})
    options.merge!(:headers => { "Authorization: OAuth" => @oauth })
    HTTParty.send(action, url, options)
  end
end
