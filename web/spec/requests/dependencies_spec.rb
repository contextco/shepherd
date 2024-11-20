require 'rails_helper'

RSpec.describe "Dependencies", type: :request do
  let(:user) { create(:user) }
  let(:version) { create(:project_version, team: user.team) }

  before { login_as user }

  describe "GET /index" do
    subject { get version_dependencies_path(version) }

    it "returns http success" do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    let(:dependency_object) { Chart::Dependency.from_name!('postgresql') }

    subject { post version_dependencies_path(version), params: { dependency: {
      name: dependency_object.name,
      version: dependency_object.variants.sample.version,
      repo_url: dependency_object.repository,
      configs: {
        cpu_cores: '1',
        memory_bytes: 1.gigabyte.to_s,
        disk_bytes: 1.gigabyte.to_s
      }
    } } }

    it "creates a new dependency" do
      expect { subject }.to change { version.reload.dependencies.count }.by(1)
    end

    it "redirects to the version page" do
      subject
      expect(response).to redirect_to(version_path(version))
    end

    context 'when using an illegal name' do
      subject { post version_dependencies_path(version), params: { dependency: {
        name: 'Test',
        version: dependency_object.variants.sample.version,
        repo_url: dependency_object.repository
      } } }

      it 'returns an error' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when using an illegal version' do
      subject { post version_dependencies_path(version), params: { dependency: {
        name: dependency_object.name,
        version: '1.0.0',
        repo_url: dependency_object.repository
      } } }

      it 'returns an error' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when using an illegal repo_url' do
      subject { post version_dependencies_path(version), params: { dependency: {
        name: dependency_object.name,
        version: dependency_object.variants.sample.version,
        repo_url: 'http://example.com'
      } } }

      it 'returns an error' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when adding multiple dependencies of the same name' do
      subject do
        2.times do
          post version_dependencies_path(version), params: { dependency: {
            name: dependency_object.name,
            version: dependency_object.variants.sample.version,
            repo_url: dependency_object.repository,
            configs: {
              cpu_cores: '1',
              memory_bytes: 1.gigabyte.to_s,
              disk_bytes: 1.gigabyte.to_s
            }
          } }
        end
      end

      it 'only creates 1 dependency' do
        expect { subject }.to change(version.dependencies, :count).by(1)
      end
    end
  end
end
