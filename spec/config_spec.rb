require 'config'

require 'tempfile'
require 'fileutils'

RSpec.describe 'Config' do

  let(:token) { '1234' }
  let(:new_token) { token + 'abcd' }
  

  let(:current_project) { 789 }
  let(:api_url) { 'https://example.com/api' }
  let(:config_file_contents) { {token: token, current_project: current_project, api_url: api_url} }
  
  before do
    Config.class_variable_set('@@config', nil)
    Config.class_variable_set('@@dirty', nil)

    config_file=Tempfile.new
    
    @config_filepath = config_file.path
    
    if config_file_contents
      File.open(@config_filepath, 'w') do |f|
        f.write( config_file_contents.to_json )
      end
    else
      config_file.unlink
    end
    
    stub_const('Config::CONFIG_FILE', @config_filepath)
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
               .to(config_file_contents.merge(token: new_token).to_json)
      end

      it 'resets the dirty flag' do
        expect { subject }.to change { Config.dirty? }.from(true).to(false)
      end
    end
  end
end
