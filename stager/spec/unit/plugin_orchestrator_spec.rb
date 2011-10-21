require File.join(File.dirname(__FILE__), 'spec_helper')

require 'fileutils'
require 'tmpdir'

describe VCAP::Stager::PluginOrchestrator do
  describe '#run_plugins' do
    before :each do
      @src_dir = Dir.mktmpdir
      @dst_dir = Dir.mktmpdir
      @cc_info = {
        'host'    => '127.0.0.1',
        'port'    => 9090,
        'task_id' => 'test_task_id',
      }
      @app_props = {
        'id'               => 1,
        'name'             => 'testapp',
        'framework'        => 'sinatra',
        'runtime'          => 'ruby18',
        'plugins'          => [],
        'service_configs'  => [],
        'service_bindings' => [],
        'resource_limits'  => {
          'memory' => 128,
          'disk'   => 2048,
          'fds'    => 1024,
        }
      }
      VCAP::Stager::PluginRegistry.reset()
    end

    after :each do
      FileUtils.rm_rf(@src_dir)
      FileUtils.rm_rf(@dst_dir)
    end

    it 'should raise an error for unknown plugins' do
      @app_props['plugins'] = [{'gem' => {'name' => 'invalid_gem'}}]
      orch = VCAP::Stager::PluginOrchestrator.new(@src_dir, @dst_dir, @app_props, @cc_info)
      expect do
        orch.run_plugins
      end.to raise_error(LoadError)
    end

    it 'should raise an error if no framework plugin is supplied' do
      orch = VCAP::Stager::PluginOrchestrator.new(@src_dir, @dst_dir, @app_props, @cc_info)
      expect do
        orch.run_plugins
      end.to raise_error(VCAP::Stager::MissingFrameworkPluginError)
    end

    it 'should raise an error if > 1 framework plugins are supplied' do
      plugins = []
      2.times do |i|
        p = create_mock_plugin("plugin_#{i}", :framework)
        VCAP::Stager::PluginRegistry.register_plugin(p)
      end
      orch  = VCAP::Stager::PluginOrchestrator.new(@src_dir, @dst_dir, @app_props, @cc_info)
      expect do
        orch.run_plugins
      end.to raise_error(VCAP::Stager::DuplicateFrameworkPluginError)
     end

    it 'should raise an error if a plugin of unknown type is supplied' do
      p = create_mock_plugin(:plugin0, :invalid_plugin_type)
      VCAP::Stager::PluginRegistry.register_plugin(p)
      orch = VCAP::Stager::PluginOrchestrator.new(@src_dir, @dst_dir, @app_props, @cc_info)
      expect do
        orch.run_plugins
      end.to raise_error(VCAP::Stager::UnknownPluginTypeError)
    end

    it 'should call stage on each of the registered plugins' do
      plugin_types = [:framework, :feature, :feature]
      plugin_types.each_with_index do |ptype, ii|
        p = create_mock_plugin("plugin_#{ii}", ptype)
        p.should_receive(:stage).with(any_args())
        VCAP::Stager::PluginRegistry.register_plugin(p)
      end
      orch = VCAP::Stager::PluginOrchestrator.new(@src_dir, @dst_dir, @app_props, @cc_info)
      orch.run_plugins
    end
  end

  def create_mock_plugin(name, type)
    ret = mock(name)
    ret.stub(:plugin_type).and_return(type)
    ret.stub(:name).and_return(name)
    ret
  end
end
