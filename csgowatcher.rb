require 'yaml'
require 'json'
require 'open-uri'
require 'htmlentities'
require 'pushover'

class CSGOWatcher

  @@config = YAML::load(File.open('config.yml'))


  def get_current_price(name)
    
    url = "#{@@config['base_url']}#{name}"
    url = URI::encode(url)
    puts url
    open(url) do |f|
      response = f.read
      response = JSON.parse(response)
      if response['success']
        unless response['lowest_price'].nil?
          value = response['lowest_price']
          value.gsub!('£','')
        end
      end
    end
  end

  def send_push_message(name,message,title)
    contacts = @@config['pushover']
    contacts.each do |contact|
      if contact['name'] == name
        @push_details = contact
      end
    end
    
    unless @push_details.nil? 
      Pushover.notification(message: message, title: title, user: @push_details['user_key'], token: @push_details['app_key'])
    end

  end

  def run()
    @@config['items'].each do |item|
      value = self.get_current_price(item['name'])
      unless value.nil?
        if value.to_f < item['minimum_price'].to_f
          difference = item['minimum_price'].to_f - value.to_f
          percentage = difference / item['minimum_price'].to_f * 100
          msg = "WIN: #{item['name']} is currently available for #{value}! #{percentage} lower than your budget."
          self.send_push_message(item['notify'],msg,'quick! get it!')
        else
          msg = "CRAP: #{item['name']} is currently not currently cheap at #{value}, your minimum is #{item['minimum_price']}"
        end

      else
        msg = "#{item['name']} is not currently available on the store"
      end  
      puts msg
    end

  end

end

csgo = CSGOWatcher.new
csgo.run()
