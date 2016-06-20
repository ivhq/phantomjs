require 'spec_helper'

describe 'phantomjs::default' do
  let(:version)  { '1.9.7' }
  let(:base_url) { 'http://example.com/' }
  let(:src_dir)  { '/src' }
  let(:prefix)   { '/usr' }
  let(:basename) { "phantomjs-1.9.7" }

  let(:runner) {
    runner = ChefSpec::ChefRunner.new(platform: 'ubuntu', version: '12.04')

    runner.node.set['phantomjs']['version']  = version
    runner.node.set['phantomjs']['base_url'] = base_url
    runner.node.set['phantomjs']['src_dir']  = src_dir
    runner.node.set['phantomjs']['prefix']   = prefix

    runner.converge('phantomjs::default')
  }

  it 'includes the `structure` recipe' do
    expect(runner).to include_recipe('phantomjs::structure')
  end

  it 'downloads the tarball' do
    expect(runner).to create_remote_file("#{src_dir}/#{basename}.tar.bz2")
  end

  it 'is owned by the root user' do
    download = runner.remote_file("#{src_dir}/#{basename}.tar.bz2")
    expect(download).to be_owned_by('root', 'root')
  end

  it 'has 0644 permissions' do
    download = runner.remote_file("#{src_dir}/#{basename}.tar.bz2")
    expect(download.mode).to eq('0644')
  end

  it 'notifies the execute resource' do
    download = runner.remote_file("#{src_dir}/#{basename}.tar.bz2")
    expect(download).to notify('execute[phantomjs-install]', :run)
  end

  it 'extracts the binary' do
    expect(runner).to execute_command("tar -xvjf #{src_dir}/#{basename}.tar.bz2 -C #{prefix}")
  end

  it 'notifies the link' do
    command = runner.execute('phantomjs-install')
    expect(command).to notify('link[phantomjs-link]', :create)
  end

  it 'creates the symlink' do
    link = runner.link('phantomjs-link')
    expect(link.target_file).to eq(::File.join(prefix, 'bin', 'phantomjs'))
    expect(link.to).to eq(::File.join(prefix, basename, 'bin', 'phantomjs'))
  end
end
