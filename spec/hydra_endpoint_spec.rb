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
    expect(subject.should_advance_work?).to be_truthy
  end

  it 'can upload a file' do
    expect(subject.upload(file)).to be_truthy
  end

  it 'can clear the csrf token' do
    subject.instance_variable_set(:@csrf_token, '8675309')
    subject.clear_csrf_token
    expect(subject.instance_variable_get(:@csrf_token)).to be_nil
  end

  context 'when auto_advance_work is set to false' do
    before :each do
      work_type_config.merge!('hydra_endpoint' => { 'workflow_actions' => { 'auto_advance_work' => false } })
    end
    it 'has should_advance_work? set to false' do
      expect(subject.should_advance_work?).to be_falsey
    end
  end

  context 'with a mocked csrf_token' do
    before :each do
      data[subject.csrf_form_field] = subject.get_csrf_token(config['server_domain'])
    end

    context 'when publishing an existing work JSON file' do
      let(:work_response) { subject.publish_work(data) }
      it 'can publish_work' do
        expect(subject).to receive(:post_data).with(subject.new_work_action, JSON.generate(data), headers).and_return(mock_return)
        expect(work_response).to eq mock_hydra_endpoint_response
      end
    end

    context 'when submitting a new work' do
      let(:work_response) { subject.submit_new_work(bag, data) }
      it 'can submit_new_work' do
        expect(subject).to receive(:cache_data).with(data, bag.item_cache_path)
        expect(subject).to receive(:publish_work).with(data, {}).and_return(mock_hydra_endpoint_response)
        expect(work_response).to eq mock_hydra_endpoint_response
      end
    end

    context 'when advancing a work through a workflow' do
      let(:work_response) { subject.advance_workflow(mock_hydra_endpoint_response, headers) }
      it 'can advance_workflow' do
        expect(subject).to receive(:json_headers).and_return({})
        expect(subject).to receive(:workflow_actions_data).with('name').and_return('workflow_action' => { 'name' => 'approve' })
        expect(subject).to receive(:workflow_actions_data).with('comment').and_return('workflow_action' => { 'comment' => 'a comment' })
        expect(subject).to receive(:workflow_actions_url).and_return('')
        expect(subject).to receive(:put_data).and_return(mock_return)
        expect(work_response).to eq mock_hydra_endpoint_response
      end
    end
  end
end
