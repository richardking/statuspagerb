require 'rubygems'
require 'httparty'
require 'yaml'

class StatusPage
  attr_accessor :components, :incidents, :unresolved_incidents
  attr_reader :api_url, :manage_url

  COMPONENT_STATUS = [:operational, :degraded_performance, :partial_outage, :major_outage]
  REALTIME_STATUS = [:investigating, :identified, :monitoring, :resolved ]
  SCHEDULED_STATUS = [:scheduled, :in_progress, :verifying, :completed]

  def initialize
    @config = File.join(Dir.getwd, ENV['STATUS_PAGE_DIR'] || 'config', 'statuspage.yml')
    @components = {}
    @incidents = {}
    @unresolved_incidents = {}

    load_config
    load_components
    load_incidents
  end

  def component_by(args_hash)
    component_id = args_hash[:id] || @components[args_hash[:name].downcase]['id']
    get_components_json.select{|c| c['id'] == component_id }.first
  end

  def update_component(args_hash)
    url = "#{@api_url}/components/#{args_hash[:id] || component_by(args_hash)['id']}.json"
    httparty_send(:patch, url, :body => {"component[status]" => args_hash[:status] }).body
  end

  def incident_by(args_hash)
    incident_id = args_hash[:id] || @incidents[args_hash[:name].downcase]['id']
    get_incidents_json.select{|i| i['id'] == incident_id }.first
  end

  def unresolved_incident_by(args_hash)
    return @unresolved_incidents[args_hash[:name].downcase] unless args_hash[:id]
    @unresolved_incidents.select{|i| i['id'] == args_hash[:id]}.first
  end

  def create_incident(args_hash)
    options = { body: { "incident[name]" => args_hash[:name], "incident[status]" => args_hash[:status],  "incident[message]" => args_hash[:message] } }
    options[:body].merge!({"incident[scheduled_for]=" => args_hash[:start_time], "incident[scheduled_until]" => args_hash[:end_time]}) if args_hash[:start_time]
    httparty_send(:post, "#{@api_url}/incidents.json", options).body
  end

  def update_incident(args_hash)
    options = { :body => { "incident[status]" => args_hash[:status], "incident[message]" => args_hash[:message] } }
    httparty_send(:patch, "#{@api_url}/incidents/#{args_hash[:id]}.json", options).body
  end

  def tune_incident_update(args_hash)
    puts args_hash
    options = { :body => { "incident_update[body]" => args_hash[:message]} }
    httparty_send( :patch, "#{@api_url}/incidents/#{args_hash[:id]}/incident_updates/#{args_hash[:update_id]}.json", options).body
  end

  private

  def load_config
    config = YAML.load(File.open @config)
    config = config[ENV['STATUS_PAGE_CONFIG']] if ENV['STATUS_PAGE_CONFIG']

    @oauth = config['oauth']
    @base_url = config['api_url']
    @manage_url = config['manage_url']
    @page = config['page']
    @api_url = @base_url + @page
    @manage_url = @manage_url + @page
  end

  def load_components
    get_components_json.each {|c| @components[c['name'].downcase] = c }
  end

  def load_incidents
    get_incidents_json.each do |i|
      @incidents[i['name'].downcase] = i
      @unresolved_incidents[i['name'].downcase] = i unless ['resolved', 'postmortem', 'completed'].include? i['status']
    end
  end

  def load_unresolved_incidents
    @incidents
  end

  def get_components_json
    httparty_send(:get, "#{@api_url}/components.json")
  end

  def get_incidents_json
    httparty_send(:get, "#{@api_url}/incidents.json")
  end

  def httparty_send(action, url, options={})
    options.merge!(:headers => { "Authorization: OAuth" => @oauth })
    HTTParty.send(action, url, options)
  end

end
