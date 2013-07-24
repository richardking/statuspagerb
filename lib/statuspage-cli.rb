require 'rubygems'
require 'httparty'
require 'yaml'
require_relative 'statuspage'

class StatusPageCLI
  COMPONENT_STATUSES = ["operational", "degraded performance", "partial outage", "major outage"]
  INCIDENT_STATUSES = ["investigating", "identified", "monitoring", "resolved"]

  def initialize(args=nil)
    @status_page = StatusPage.new
    start(args) if args
  end

  def start(args=[])
    command = args.shift
    if self.respond_to? command
      send(command, *args)
    else
      raise "Command not recognized"
    end
  end

  def update_component_by_name(name, status)
    components = @components_hash.keys.grep(/#{name.downcase}/)

    if components.size == 0
      raise "Cannot find component matching '#{name}'"
    elsif components.size == 1
      url = "#{@account_url}/components/#{components.first.value}.json"
      httparty_send :patch, url, :body => {"component[status]" => status }
    else
      raise "Multiple components matching '#{name}'"
    end
  end

  # components - show status of all components
  # components <component_name> - show status of specific component
  # components <component_name> <status> - set the status for a component
  def components(*arg)
    if args.empty?
      @status_page.show_all_components
    elsif args.one?
      component_name = @status_page.components_hash.keys.grep(/#{args[0].downcase}/).first
      component_id = @status_page.components_hash["#{component_name}"]

      component = @status_page.get_components_json.select{|c| c['id'] == component_id}.first
      puts "Status of #{component['name']}: #{component['status'].gsub('_',' ')}"
    else 
      valid_component_status?(args[1].downcase)
      component_name = @components_hash.keys.grep(/#{args[0].downcase}/).first
      component_id = @components_hash["#{component_name}"]
      component_new_status = COMPONENT_STATUSES.grep(/#{args[1].downcase}/).first

      response = @status_page.update_component_by_id(component_id, component_new_status)
      puts "Status for #{component_name} is now #{response['status'].gsub('_',' ')}"
    end
  end

  # incidents - show json of all incidents
  # incidents open <incident_name> <incident_status> <incident_message> - create new incident
  # incidents update <incident_name> <incident_status> <incident_message> - update specific incident with new status/message
  def incidents(*args)
    unresolved_incidents = @status_page.show_unresolved_incidents
    if args.empty?
      if unresolved_incidents.empty?
        puts "No unresolved incidents"
      else
        puts "Unresolved incidents:"
        unresolved_incidents.each do |i|
          puts "#{i['name']} - status: #{i['status']}, created at #{i['created_at']}"
        end
      end
    elsif args[0] == 'open'
      options = { :body => { "incident[name]" => args[1], "incident[status]" => args[2],  "incident[message]" => args[3] } }
      response = @status_page.open_incident(args[1], args[2], args[3])
      puts "Created new incident: #{response['name']}"
    elsif args[0] == 'update'
      incident_names = incidents_hash.keys.grep(/#{args[0].downcase}/)
      if incident_names.size == 0
        raise "Cannot find incident matching '#{args[0]}'"
      elsif incident_names.size == 1
        response = @status_page.update_incident_by_id(@status_page.incidents_hash[incident_names.first], args[2], args[3])
        puts "Updated incident '#{response['name']}' status to #{response['status']}"
      else
        raise "Multiple incidents matching '#{args[0]}'"
      end
    else
      raise "Invalid incidents action"
    end
  end

  private

  def component_name_valid?(name)
    unless @status_page.components_hash.keys.detect {|n| n =~ /#{name}/}
      raise "Invalid component name"
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
end
