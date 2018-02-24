require 'ostruct'
require 'json'
require 'tempfile'
require 'fileutils'

class Config

  CONFIG_FILE = File.join(ENV['HOME'], '.pivotal_tracker_cli.json')

  class << self
    
    [:token,
     :current_project,
     :api_url].each do |accessor|
      send(:define_method, accessor) do
        config[accessor.to_s]
      end

      send(:define_method, (accessor.to_s + '=').to_sym) do |value|
        @@config=config.merge( accessor.to_s => value ).freeze
        @@dirty=true
        @@empty=false
      end
    end

    def dirty?
      @@dirty ||= false
    end

    def empty?
      @@empty ||= config.empty?
    end
    
    def save
      if dirty?
        Tempfile.open do |f|
          f.write(config.to_json)
          f.flush
          FileUtils.copy(f.path, CONFIG_FILE, preserve: true)
          @@dirty = false
        end
      end
    end
    
    private

    def config
      @@config ||=
        if File.exist? CONFIG_FILE
          JSON.parse(File.read(CONFIG_FILE)).freeze
        else
          @@empty=true
          {}.freeze
        end
    rescue => e
       raise "unable to load config file #{CONFIG_FILE}"
    end
    
  end
end
