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

   before do
      Tiun.setup_with('spec/fixtures/samples/users.yaml')
   end

   it "has a version number" do
      #  binding.pry
      expect(Tiun::VERSION).not_to be nil
   end

   describe 'tiun core' do
     subject { Tiun }

      it { expect(subject.routes.map {|x| x.path }).to match_array([ "/v1/users/:id.json" ]) }
      it { expect(subject.controllers.map {|x| x.name }).to match_array([ "::V1::UsersController" ]) }
      it { expect(subject.policies.map {|x| x.name }).to match_array([ "UserPolicy" ]) }
      it { expect(subject.models.map {|x| x.name }).to match_array([ "User" ]) }
      it { expect(subject.migrations.map {|x| x.name }).to match_array([ "CreateUsers" ]) }
      it { expect(subject.serializers.map {|x| x.name }).to match_array([ "UserSerializer" ]) }
      xit { expect(subject.controllers.values).to match_array([ V1::UsersController ]) }
      xit { expect(subject.tiuns).to match_array([User]) }

      describe 'defaults' do
         it { expect(subject.base_controller).to eq(ActionController::Base) }
         it { expect(subject.base_model).to eq(ActiveRecord::Base) }
         xit { expect(subject.base_migration).to eq(ActiveRecord::Migration) }
      end
   end

   xcontext 'serializers' do
      it { expect(subject.settings).to match_hash(settings) }
      it { expect(subject.tiuns).to match_array([User]) }
   end

   xcontext 'controllers' do
      it { expect(subject.settings).to match_hash(settings) }
      it { expect(subject.tiuns).to match_array([User]) }
   end

   xcontext 'policies' do
      it { expect(subject.settings).to match_hash(settings) }
      it { expect(subject.tiuns).to match_array([User]) }
   end

   xcontext 'models' do
      it { expect(subject.settings).to match_hash(settings) }
      it { expect(subject.tiuns).to match_array([User]) }
   end

   xcontext 'support method setup_classes' do
      before do
#         eval "class TestModelsController < ActiveRecord::Base; end" unless defined?(TestModelsController)
#         eval "class TestModelPolicy; end" unless defined?(TestModelPolicy)

#         Tiun.setup_classes(settings)
      end

      context 'when access to Tiun::TestModelsController' do
         it { expect{ Tiun::UsersController }.to_not raise_error  }
      end

      context 'when access to Tiun::TestModelPolicy' do
         it { expect{ Tiun::UserPolicy }.to_not raise_error  }
      end
   end
end
