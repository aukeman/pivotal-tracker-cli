require 'utils'

require 'tmpdir'

RSpec.describe 'Utils' do
  describe '#terminal_size' do

    subject { Utils.terminal_size }
    
    let(:columns) { 388 }
    let(:lines) { 125 }

    context '$COLUMNS and $LINES env variables are defined' do
      before do
        @original_lines=ENV['LINES'] if ENV['LINES']
        @original_columns=ENV['COLUMNS'] if ENV['COLUMNS']

        ENV['COLUMNS'] = columns.to_s
        ENV['LINES'] = lines.to_s
      end

      after do
        if @original_lines
          ENV['LINES'] = @original_lines
        else
          ENV.delete('LINES')
        end

        if @original_columns
          ENV['COLUMNS'] = @original_columns
        else
          ENV.delete('COLUMNS')
        end
      end

      it 'uses $COLUMNS and $LINES to report terminal size' do
        expect(subject).to eq([columns, lines])
      end
    end

    context '$COLUMNS and $LINES env variables are not defined' do
      before do
        @original_lines=ENV['LINES'] if ENV['LINES']
        @original_columns=ENV['COLUMNS'] if ENV['COLUMNS']

        ENV.delete('COLUMNS')
        ENV.delete('LINES')
      end

      after do
        ENV['LINES'] = @original_lines if @original_lines
        ENV['COLUMNS'] = @original_columns if @original_columns
      end

      context 'and tput command is available' do

        before do
          @temp_dir=Dir.mktmpdir
          
          File.open(File.join(@temp_dir, 'tput'), 'w', 0700) do |f|
            f.puts %q(#!/bin/bash)
            f.puts %q(if [[ $1 == 'cols' ]]; then)
            f.puts %Q(  echo #{columns})
            f.puts %q(elif [[ $1 == 'lines' ]]; then)
            f.puts %Q(  echo #{lines})
            f.puts %q(fi)
          end

          @old_path=ENV['PATH']
          ENV['PATH'] = "#{@temp_dir}"
        end

        after do
          FileUtils.remove_entry(@temp_dir)
          ENV['PATH'] = @old_path
        end
        
        it 'uses tput output to report terminal size' do
          expect(subject).to eq([columns, lines])
        end
      end

      context 'and tput command is not available' do
        context 'and stty command is available' do
          before do
            @temp_dir=Dir.mktmpdir
            
            File.open(File.join(@temp_dir, 'stty'), 'w', 0700) do |f|
              f.puts %q(#!/bin/bash)
              f.puts %q(if [[ $1 == 'size' ]]; then)
              f.puts %Q(  echo #{lines} #{columns})
              f.puts %q(fi)
            end

            @old_path=ENV['PATH']
            ENV['PATH'] = "#{@temp_dir}"
          end

          after do
            FileUtils.remove_entry(@temp_dir)
            ENV['PATH'] = @old_path
          end

          it 'uses stty output to report terminal size' do
            expect(subject).to eq([columns, lines])
          end
          
        end
      end
    end  
  end

  describe '#command_exists?' do

    subject { Utils.command_exists?(command) }
    
    let(:command) { 'command_to_find' }
    let(:permissions) { 0700 }

    before do
      @temp_dir=Dir.mktmpdir
      
      File.open(File.join(@temp_dir, command), 'w', permissions) do |f|
        f.puts %q(#!/bin/bash)
        f.puts %q(echo 'hello, world')
      end
    end

    after do
      FileUtils.remove_entry(@temp_dir)
    end
    
    context 'path is empty' do
      before do
        @old_path = ENV['PATH']
        ENV['PATH']=''
      end

      after do
        ENV['PATH'] = @old_path
      end

      it { is_expected.to eq(false) }
    end

    context 'path only contains the command directory' do
      before do
        @old_path = ENV['PATH']
        ENV['PATH'] = @temp_dir
      end

      after do
        ENV['PATH'] = @old_path
      end

      context 'and the command is executable' do
        it { is_expected.to eq(true) }
      end

      context 'and the command is not executable' do
        let(:permissions) { 0600 }
        it { is_expected.to eq(false) }
      end
    end

    context 'path includes the command directory' do
      before do
        @old_path = ENV['PATH']
        ENV['PATH'] = [ENV['PATH'], @temp_dir].join(File::PATH_SEPARATOR)
      end

      after do
        ENV['PATH'] = @old_path
      end

      context 'and the command is executable' do
        it { is_expected.to eq(true) }
      end

      context 'and the command is not executable' do
        let(:permissions) { 0600 }
        it { is_expected.to eq(false) }
      end
    end

  end
end
