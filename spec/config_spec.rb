require 'config'

require 'tempfile'
require 'fileutils'

RSpec.describe 'Config' do

  let(:token) { '1234' }
  let(:new_token) { token + 'abcd' }
  

  let(:current_project) { 789 }
  let(:api_url) { 'https://example.com/api' }
  let(:config_file_contents) { {'token' => token, 'current_project' => current_project, 'api_url' => api_url} }
  
  before do
    config_file=Tempfile.new
    
    @config_filepath = config_file.path
    
    if config_file_contents.nil?
      config_file.unlink
    else
      File.open(@config_filepath, 'w') do |f|
        f.write( config_file_contents.to_json )
      end
    end
    
    stub_const('Config::CONFIG_FILE', @config_filepath)

    Config.load
  end

  after do
    File.delete(@config_filepath) if File.exist?(@config_filepath)
  end
  
  subject { Config }
  
  it { is_expected.to respond_to(:token) }
  it { is_expected.to respond_to(:current_project) }
  it { is_expected.to respond_to(:api_url) }

  it { is_expected.to respond_to(:token=) }
  it { is_expected.to respond_to(:current_project=) }
  it { is_expected.to respond_to(:api_url=) }

  context 'when the config file exists' do
    it 'takes the token value from the file' do
      expect(Config.token).to eq(token)
    end

    it 'takes the current_project value from the file' do
      expect(Config.current_project).to eq(current_project)
    end

    it 'takes the api_url value from the file' do
      expect(Config.api_url).to eq(api_url)
    end

    context 'a value is changed' do
      subject { Config.token = new_token }

      it 'the new value is reflected' do
        expect { subject }.to change {Config.token}.from(token).to(new_token)
      end

      it 'other items are not mutated' do
        expect { subject }.not_to change {Config.api_url}.from(api_url)
      end

      it 'sets the dirty flag' do
        expect { subject }.to change{Config.dirty?}.from(false).to(true)
      end
    end
  end

  context 'when the config file does not exist' do
    let(:config_file_contents) { nil }
    
    it 'returns a nil value for token' do
      expect(Config.token).to be_nil
    end
  end

  context 'when the configuration is not loaded' do
    before do
      Config.class_variables.each do |cv|
        Config.class_variable_set(cv, nil)
      end
    end

     
  end
  
  describe '#load' do
    before do
      Config.class_variables.each do |cv|
        Config.class_variable_set(cv, nil)
      end
    end
    
    context 'when using the default config file' do
      subject { Config.load }

      it 'loads the configuration from the default file' do
        expect { subject }
          .to change { Config.class_variable_get('@@config') rescue nil }
               .from(nil)
               .to(config_file_contents)
      end
    end

    context 'when an override config file is provided' do
      subject { Config.load @config_filepath }
      
      let(:default_config_filepath) do
        # generate a temporary filename
        # the actual file gets unlinked so it doesn't exist
        Tempfile.open { |f| f.path } 
      end

      # override the default config filepath with a file that doesn't exist
      before do
        stub_const('Config::CONFIG_FILE', default_config_filepath)
      end

      it 'loads the configuration from the default file' do
        expect { subject }
          .to change { Config.class_variable_get('@@config') rescue nil }
               .from(nil)
               .to(config_file_contents)
      end
    end
  end

  
  describe '#save' do
    subject { Config.save }

    before do
      if File.exist?(@config_filepath)
        FileUtils.touch(@config_filepath, mtime: Time.now - 3600)
      end
    end
    
    context 'when the configuration is unchanged' do

      it 'does not update the config file' do
        expect { subject }.not_to change { File.mtime(@config_filepath) }
      end

      it 'does not modify the contents of the config file' do
        expect { subject }
          .not_to change { File.read(@config_filepath) }
                   .from(config_file_contents.to_json)
      end

      it 'does not change the dirty flag' do
        expect { subject }.not_to change { Config.dirty? }.from(false)
      end
    end

    context 'when the configuration changes' do
      before do
        Config.token = new_token
      end

      it 'updates the config file' do
        expect { subject }.to change { File.mtime(@config_filepath) }
      end

      it 'writes the current the configuration to the config file' do
        expect { subject }
          .to change { File.read(@config_filepath) }
               .to(config_file_contents.merge('token' => new_token).to_json)
      end

      it 'resets the dirty flag' do
        expect { subject }.to change { Config.dirty? }.from(true).to(false)
      end
    end

    context 'when the configuration file is missing' do 
      let(:config_file_contents) { nil }

      context 'and the configuration is empty' do
        before do
          expect(Config.empty?).to eq(true)
        end

        it 'does not save the file' do
          expect { subject }.not_to change { File.exist? @config_filepath }.from(false)
        end
      end
        
      context 'and configuration has been updated' do
        before do
          Config.token = new_token
        end

        it 'saves the file' do
          expect { subject }.to change { File.exist? @config_filepath }.from(false).to(true)
        end

        it 'writes the new configuration to the file' do
          expect { subject }.to change { File.read @config_filepath rescue nil }.to({token: new_token}.to_json)
        end
      end
    end
  end

  describe '#dirty?' do
    before { Config.token } # ensure the config is loaded

    subject { Config.dirty? }

    context 'when the configuration file exists' do
      context 'and something nothing has changed' do
        it { is_expected.to eq(false) }
      end

      context 'and has changed' do
        before { Config.token = new_token }
        it { is_expected.to eq(true) }
      end
    end
    
    context 'when the config file does not exist' do
      let(:config_file_contents) { nil }
      it { is_expected.to eq(false) }
    end
  end

  describe '#empty?' do
    subject { Config.empty? }

    context 'when the configuration file exists' do
      context 'and nothing has changed' do
        it { is_expected.to eq(false) }
      end

      context 'and something has changed' do
        before { Config.token = new_token }
        it { is_expected.to eq(false) }
      end
    end
    
    context 'when the config file does not exist' do
      let(:config_file_contents) { nil }

      context 'and nothing has changed' do
        it { is_expected.to eq(true) }
      end

      context 'and something has changed' do
        before { Config.token = new_token }
        it { is_expected.to eq(false) }
      end
    end
  end
end
