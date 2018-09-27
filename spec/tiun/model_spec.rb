RSpec.describe Tiun::Model do

   let(:tiun) do
      {:fields=>{
         :id=>{ :type=>:integer },
         :str=>{ :type=>:string },
         :int=>{ :type=>:integer },
         :bool=>{ :type=>:boolean },
         :txt=>{ :type=>:text },
         :date=>{ :type=>:date },
         :time=>{ :type=>:datetime }
      }}
   end

   context 'instance method' do
      before do
         TestModel.connection
      end

      subject { TestModel }

      context '#tiun' do
         it { expect(subject.tiun).to match_hash(tiun) }
      end

      context '#tiuns' do
         it { expect(subject.tiuns).to match_array([TestModel]) }
      end
   end
end
