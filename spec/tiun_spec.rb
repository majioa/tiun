RSpec.describe Tiun do

   let(:settings) do
      {:test_model =>
      {:fields=>{
         :id=>{ :type=>:integer },
         :str=>{ :type=>:string },
         :int=>{ :type=>:integer },
         :bool=>{ :type=>:boolean },
         :txt=>{ :type=>:text },
         :date=>{ :type=>:date },
         :time=>{ :type=>:datetime }
      }}}
   end

   it "has a version number" do
      expect(Tiun::VERSION).not_to be nil
   end

   context 'class' do
      subject { Tiun }

      before do
         TestModel.connection
      end

      it { expect(subject.settings).to match_hash(settings) }
      it { expect(subject.tiuns).to match_array([TestModel]) }
      it { expect(subject.base_controller).to eq(ActionController::Base) }
   end

   context 'support method setup_classes' do
      before do
         Tiun.setup_classes(settings)
      end

      context 'when access to Tiun::TestModelsController' do
         it { expect{ Tiun::TestModelsController }.to_not raise_error  }
      end

      context 'when access to Tiun::TestModelPolicy' do
         it { expect{ Tiun::TestModelPolicy }.to_not raise_error  }
      end
   end
end
