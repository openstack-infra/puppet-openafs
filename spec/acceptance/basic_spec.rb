require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'openafs', :if => ['debian', 'ubuntu'].include?(os[:family]) do

  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def puppet_manifest
    module_path = File.join(pp_path, 'default.pp')
    File.read(module_path)
  end

  it 'should work with no errors' do
    apply_manifest(puppet_manifest, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(puppet_manifest, catch_changes: true)
  end

  ['openafs-client', 'openafs-fileserver'].each do |service|
    describe command("systemctl status #{service}") do
      its(:stdout) { should contain('Active: active') }
      its(:stdout) { should_not contain('dead') }
    end
  end

end
