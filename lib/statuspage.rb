require 'rubygems'
require 'httparty'
require 'yaml'

class StatusPage
  attr_accessor :components_hash, :incidents_hash

  def initialize
    @config = File.expand_path("~/.statuspage.yml")
    @components_hash = {}
    @incidents_hash = {}

    load_config
    load_components
    load_incidents
  end
  
  def load_config
    config = YAML.load(File.open @config)
    @oauth = config['oauth']
    @base_url = config['base_url']
    @page = config['page']
    @account_url = @base_url + @page
  end

  def show_all_components
    get_components_json
  end

  def show_component_by_name(name)
    get_components_json.select{|c| c['id'] == @components_hash[name.downcase] }
  end

  def show_component_by_id(id)
    get_components_json.select{|c| c['id'] == id }
  end

  def update_component_by_id(id, status)
    url = "#{@account_url}/components/#{id}.json"
    httparty_send :patch, url, :body => {"component[status]" => status }
  end

  def show_all_incidents
    get_incidents_json
  end

  def show_unresolved_incidents
    unresolved_incidents = get_incidents_json.reject {|i| ['resolved', 'postmortem', 'completed'].include? i['status']}
  end

  def open_incident(name, status="investigating", message=nil)
    options = { :body => { "incident[name]" => name, "incident[status]" => status,  "incident[message]" => message } }
    httparty_send :post, "#{@account_url}/incidents.json", options
  end

  def update_incident_by_id(id, status, message=nil)
    options = { :body => { "incident[status]" => status, "incident[message]" => message } }
    httparty_send :patch, "#{@account_url}/incidents/#{id}.json", options
  end

  private

  def load_components
    get_components_json.each {|c| @components_hash[c['name'].downcase] = c['id'] }
  end

  def load_incidents
    get_incidents_json.each {|i| @incidents_hash[i['name'].downcase] = i['id'] }
  end

  def get_components_json
    httparty_send(:get, "#{@account_url}/components.json")
  end

  def get_incidents_json
    httparty_send(:get, "#{@account_url}/incidents.json")
  end

  def httparty_send(action, url, options={})
    options.merge!(:headers => { "Authorization: OAuth" => @oauth })
    HTTParty.send(action, url, options)
  end
end
