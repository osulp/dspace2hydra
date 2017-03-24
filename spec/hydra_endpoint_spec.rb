# frozen_string_literal: true
RSpec.describe HydraEndpoint do
  subject { HydraEndpoint.new(config, work_type_config) }
  let(:file) { double(File) }
  let(:data) { { 'default_work' => { 'id' => 123, 'title' => 'test' } } }
  let(:config_file) { File.open(File.join(File.dirname(__FILE__), 'fixtures/mocks/.config.yml')) { |f| YAML.safe_load(f) } }
  let(:config) { config_file['hydra_endpoint'] }
  let(:work_type_config) { File.open(File.join(File.dirname(__FILE__), 'fixtures/mocks/default.yml')) { |f| YAML.safe_load(f) } }
  let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }
  let(:bag) { double('bag', item_cache_path: config_file['item_cache_path']) }
  let(:server_domain) { config_file.dig('hydra_endpoint', 'server_domain') }
  let(:mock_return) { double('Mock Server Response', body: JSON.generate(data)) }
  let(:mock_hydra_endpoint_response) { HydraEndpoint::Response.new JSON.parse(mock_return.body), URI.join(server_domain, mock_return['location']) }
  before :each do
    allow_any_instance_of(described_class).to receive(:login).and_return(true)
    allow_any_instance_of(described_class).to receive(:post_data).and_return(true)
    allow_any_instance_of(described_class).to receive(:get_csrf_token) { 'super_l33t_tok3n' }
    allow(mock_return).to receive(:[]).with('location').and_return("/default_work/#{data['id']}")
  end

  it 'initializes without errors' do
    expect { subject }.to_not raise_exception
  end

  it 'has a new_work_url' do
    expect(subject.new_work_url).to eq URI.join(server_domain, work_type_config.dig('hydra_endpoint', 'new_work', 'url'))
  end

  it 'has a login_url' do
    expect(subject.login_url).to eq URI.join(server_domain, config.dig('login', 'url'))
  end

  it 'has a new_work_action' do
    expect(subject.new_work_action).to eq work_type_config.dig('hydra_endpoint', 'new_work', 'form_action')
  end

  it 'has a csrf_form_field' do
    expect(subject.csrf_form_field).to eq work_type_config.dig('hydra_endpoint', 'new_work', 'csrf_form_field')
  end

  it 'can upload a file' do
    expect(subject.upload(file)).to be_truthy
  end

  context 'with a mocked csrf_token' do
    before :each do
      data[subject.csrf_form_field] = subject.get_csrf_token
    end

    it 'can publish_work' do
      expect(subject).to receive(:post_data).with(subject.new_work_action, JSON.generate(data), headers).and_return(mock_return)
      expect(subject.publish_work(data)).to eq mock_hydra_endpoint_response
    end

    it 'can submit_new_work' do
      expect(subject).to receive(:cache_data).with(data, bag.item_cache_path)
      expect(subject).to receive(:publish_work).with(data, {}).and_return(true)
      expect(subject.submit_new_work(bag, data)).to be_truthy
    end
  end
end
