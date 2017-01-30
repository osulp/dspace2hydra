RSpec.describe Mapping::BasicValueHandler do
  let(:klass) { Class.new { extend Mapping::BasicValueHandler }}
  it 'returns an unprocessed value' do
    expect(klass.unprocessed('blah')).to eq "blah"
  end
  it 'returns a value with text prepended' do
    expect(klass.prepend('foo', ["oh noes!"])).to eq "oh noes! foo"
  end
end
