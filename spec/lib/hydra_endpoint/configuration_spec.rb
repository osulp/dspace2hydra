# frozen_string_literal: true
RSpec.describe HydraEndpoint::Configuration do
  subject { klass.new }
  let(:klass) { Class.new { include HydraEndpoint::Configuration } }
  let(:config_file) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/.config.yml')) { |f| YAML.safe_load(f) } }
  let(:config) { config_file['hydra_endpoint'] }
  let(:work_type_config) { File.open(File.join(File.dirname(__FILE__), '../../fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }
  let(:server_domain) { config_file.dig('hydra_endpoint', 'server_domain') }

  before do
    subject.instance_variable_set(:@config, config)
    subject.instance_variable_set(:@work_type_config, work_type_config)
  end

  it '#server_domain' do
    expect(subject.server_domain).to eq URI.parse(work_type_config.dig('hydra_endpoint', 'server_domain'))
  end

  it 'has a default #server_timeout' do
    config['server_timeout'] = nil
    expect(subject.server_timeout).to eq 60
  end

  it '#server_timeout' do
    expect(subject.server_timeout).to eq work_type_config.dig('hydra_endpoint', 'server_timeout')
  end

  it 'has a new_work_url' do
    expect(subject.new_work_url).to eq URI.join(server_domain, work_type_config.dig('hydra_endpoint', 'new_work', 'url'))
  end

  it 'has a uploads_url' do
    expect(subject.uploads_url).to eq URI.join(server_domain, config.dig('uploads', 'url'))
  end

  it 'has a admin_sets_url' do
    expect(subject.admin_sets_url).to eq URI.join(server_domain, config.dig('admin_sets', 'url'))
  end

  it 'has a authentication_header' do
    expect(subject.authentication_header).to eq 'D2H-AUTHENTICATION' => 'admin_user|blahblah'
  end

  it 'has a login_url' do
    expect(subject.login_url).to eq URI.join(server_domain, config.dig('login', 'url'))
  end

  it 'has a login_form_id' do
    expect(subject.login_form_id).to eq config.dig('login', 'form_id')
  end

  it 'has a workflow_actions_url' do
    expect(subject.workflow_actions_url(1)).to eq URI.join(server_domain, '/concern/workflow_actions/1?local=en')
  end

  it 'has a workflow_actions_field' do
    expect(subject.workflow_actions_data('name')).to eq('workflow_action' => { 'name' => 'approve' })
  end

  it 'has a new_work_action' do
    expect(subject.new_work_action).to eq work_type_config.dig('hydra_endpoint', 'new_work', 'form_action')
  end

  it 'has a csrf_form_field' do
    expect(subject.csrf_form_field).to eq config.dig('csrf_form_field')
  end

  it 'has should_advance_work? returning true by default' do
    work_type_config['hydra_endpoint'] = nil
    expect(subject.should_advance_work?).to be_truthy
  end

  it 'has should_advance_work?' do
    expect(subject.should_advance_work?).to be_truthy
  end
end
